import 'dart:async';

import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:rxdart/rxdart.dart';

enum ScanBatch { FIRST, SECOND, THIRD }

class FontBloc {
  final initialFontsList = <CzechFont>[];

  var allValidatedFontsList = <CzechFont>[];
  final ReplaySubject<CzechFont> _firstBatch = ReplaySubject();
  final ReplaySubject<CzechFont> _secondBatch = ReplaySubject();
  final ReplaySubject<CzechFont> _thirdBatch = ReplaySubject();

  Stream<int> scanCounter;
  var _scanCounter = 0;
  final BehaviorSubject<int> _scan = BehaviorSubject.seeded(0);

  FontBloc({List<CzechFont> initialFontsList}) {
    if (initialFontsList != null) {
      this.initialFontsList.addAll(initialFontsList);
    }

    scanCounter = _scan.stream;
    // TODO: refactor heavy ReplaySubject with BehaviorSubject
  }

  Stream<CzechFont> get dataStreams {
    if (initialFontsList.isNotEmpty) {
      return Stream.fromIterable(initialFontsList);
    }
    return Rx.concat([_firstBatch, _secondBatch, _thirdBatch]);
  }

  Stream<List<CzechFont>> getFilteredStream(Confidence confidence) {
    return dataStreams.scan(
      (List<CzechFont> acc, value, index) => acc..add(value),
      <CzechFont>[],
    ).map(
      (list) {
        allValidatedFontsList = List.from(list);
        return list.where((item) {
          if (confidence == Confidence.ANY) return true;
          return item.confidence == confidence;
        }).toList();
      },
    ).asBroadcastStream();
  }

  void addCzechFont(ScanBatch scanBatch, CzechFont font) {
    increaseScanCounter();

    if (scanBatch == ScanBatch.FIRST) {
      _firstBatch.add(font);
    } else if (scanBatch == ScanBatch.SECOND) {
      _secondBatch.add(font);
    } else {
      _thirdBatch.add(font);
    }
  }

  void increaseScanCounter() => _scan.add(++_scanCounter);

  void dispose() {
    _firstBatch.close();
    _secondBatch.close();
    _thirdBatch.close();
    _scan.close();
  }
}

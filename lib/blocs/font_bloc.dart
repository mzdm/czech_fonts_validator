import 'dart:async';

import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:rxdart/rxdart.dart';

enum ScanBatch { FIRST, SECOND, THIRD }

class FontBloc {
  var currFontList = <CzechFont>[];
  final ReplaySubject<CzechFont> _firstBatch = ReplaySubject();
  final ReplaySubject<CzechFont> _secondBatch = ReplaySubject();
  final ReplaySubject<CzechFont> _thirdBatch = ReplaySubject();

  Stream<int> scanCounter;
  var _scanCounter = 0;
  final BehaviorSubject<int> _scan = BehaviorSubject.seeded(0);

  FontBloc() {
    scanCounter = _scan.stream;
    // TODO: refactor heavy ReplaySubject with BehaviorSubject
  }

  Stream<CzechFont> get concatStreams =>
      Rx.merge([_firstBatch, _secondBatch, _thirdBatch]);

  Stream<List<CzechFont>> getFilteredStream(Confidence confidence) {
    return concatStreams.scan(
      (List<CzechFont> acc, value, index) => acc..add(value),
      <CzechFont>[],
    ).map(
      (list) {
        final l = list.where((item) {
          if (confidence == Confidence.ANY) return true;
          return item.confidence == confidence;
        }).toList()
          ..sort((a, b) => a.fontName.compareTo(b.fontName));
        currFontList = List.from(l);
        return l;
      },
    ).asBroadcastStream();
  }

  void addCzechFont(ScanBatch scanBatch, CzechFont font) {
    _scan.add(++_scanCounter);

    if (scanBatch == ScanBatch.FIRST) {
      _firstBatch.add(font);
    } else if (scanBatch == ScanBatch.SECOND) {
      _secondBatch.add(font);
    } else {
      _thirdBatch.add(font);
    }
  }

  void dispose() {
    _firstBatch.close();
    _secondBatch.close();
    _thirdBatch.close();
    _scan.close();
  }
}

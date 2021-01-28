import 'dart:async';

import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:rxdart/rxdart.dart';

class FontBloc {
  final ReplaySubject<CzechFont> _firstController = ReplaySubject();
  final ReplaySubject<CzechFont> _secondController = ReplaySubject();

  final BehaviorSubject<int> _length = BehaviorSubject.seeded(0);

  Stream<CzechFont> get concatStreams =>
      Rx.concat([_firstController, _secondController]);

  Stream<List<CzechFont>> getFilteredStream(Confidence confidence) {
    return concatStreams.where(
      (item) {
        if (confidence == Confidence.ANY) return true;
        return item.confidence == confidence;
      },
    ).scan(
      (List<CzechFont> accumulated, value, index) => accumulated..add(value),
      <CzechFont>[],
    ).asBroadcastStream();
  }

  FontBloc() {
    _firstController.listen((value) {
      // print('listen: ${value.toString()}');
    });
  }

  void addCzechFont(CzechFont font) {
    _length.add(++_length.value);
    _firstController.add(font);
  }

  int get getCurrStreamLength => _length.value;

  void dispose() {
    _firstController.close();
    _secondController.close();
    _length.close();
  }
}

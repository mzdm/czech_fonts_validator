import 'dart:async';

import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:rxdart/rxdart.dart';

class FontBloc {
  Stream<List<CzechFont>> fontStream;

  final BehaviorSubject<CzechFont> _firstController = BehaviorSubject();
  final BehaviorSubject<CzechFont> _secondController = BehaviorSubject();

  final BehaviorSubject<int> _length = BehaviorSubject.seeded(0);

  FontBloc() {
    fontStream = Rx.merge([_firstController]).scan(
      (List<CzechFont> accumulated, value, index) => accumulated..add(value),
      <CzechFont>[],
    ).asBroadcastStream();

    fontStream.listen((event) {
      print(event.toString());
    });
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

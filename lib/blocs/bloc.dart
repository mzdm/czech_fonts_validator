import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:rxdart/rxdart.dart';

class FontBloc {
  Stream<List<CzechFont>> fontStream;

  final BehaviorSubject<CzechFont> _first = BehaviorSubject();
  final BehaviorSubject<CzechFont> _second = BehaviorSubject();

  final BehaviorSubject<int> _length = BehaviorSubject.seeded(0);

  FontBloc() {
    fontStream = Rx.merge([_first, _second])
        .scan((List<CzechFont> accumulated, value, index) =>
            accumulated..add(value))
        .asBroadcastStream();

    _first.listen((value) {
      print('listen: ${value.toString()}');
    });
  }

  void addCzechFont(CzechFont font) {
    _length.add(++_length.value);
    _first.add(font);
  }

  int get getCurrStreamLength => _length.value;

  void dispose() {
    _first.close();
    _second.close();
    _length.close();
  }
}

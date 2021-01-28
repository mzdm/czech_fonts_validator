import 'dart:async';

import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/models/language_fonts_model.dart';
import 'package:flutter/material.dart';
import 'package:google_language_fonts/google_fonts.dart';

part 'font_validation_helper.dart';

const _baseTestPhrase = 'Prilis zlutoucky kun upel dabelske o';
const _czechTestPhrase = 'Příliš žluťoučký kůň úpěl ďábelské ó';

final _czechTextKey = GlobalKey(debugLabel: 'czechTextKey');
final _latinTextKey = GlobalKey(debugLabel: 'latinTextKey');

class FontValidationPage extends StatefulWidget {
  const FontValidationPage({
    Key key,
    @required this.fonts,
  }) : super(key: key);

  final LanguageFonts fonts;

  @override
  _FontValidationPageState createState() => _FontValidationPageState();
}

class _FontValidationPageState extends State<FontValidationPage> {
  StreamController<CzechFont> streamController;

  TextStyle textStyle;
  bool shouldValidate = false;

  @override
  void initState() {
    streamController = StreamController.broadcast();
    streamController.stream.listen((event) {
      print('listen: ${event.toString()}');
    });
    super.initState();
  }

  @override
  void dispose() {
    streamController.close();
    super.dispose();
  }

  Stream<String> _streamData() async* {
    // final streamData = Stream.fromIterable(widget.fonts.fontNames);
    final fontNamesList = widget.fonts.fontNames;
    fontNamesList.insert(0, fontNamesList[0]);

    for (var i = 0; i < fontNamesList.length; i++) {
      yield await checkNext(fontNamesList[i], i);
    }
    print('stream: ${streamController.stream.toList()}');
  }

  Future<String> checkNext(String fontName, int i) async {
    // if it is first font, then render instantly
    if (i == 0) return Future.value(fontName);

    await Future.delayed(Duration(milliseconds: 400));

    if (_areGoogleFontsRendered()) {
      final fontConfidence = _calcCzechFontConfidence();
      streamController?.sink?.add(
        CzechFont(fontName: fontName, confidence: fontConfidence),
      );
      return Future.value(fontName);
    }

    int recheckDuration = 125;
    while (!_areGoogleFontsRendered()) {
      await Future.delayed(Duration(milliseconds: recheckDuration));
      recheckDuration *= 2;

      if (recheckDuration == 8000) {
        print(
          'FAILED_CHECK: font \'$fontName\' was not successfully rendered in time',
        );
        return null;
      }
    }

    if (_areGoogleFontsRendered()) {
      final fontConfidence = _calcCzechFontConfidence();
      streamController?.sink?.add(
        CzechFont(fontName: fontName, confidence: fontConfidence),
      );
      return Future.value(fontName);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: !shouldValidate
            ? Text('Press [PLAY] button to start validating fonts')
            : buildFontValidator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => shouldValidate = true),
        tooltip: 'Start validating Czech fonts',
        child: Icon(Icons.play_arrow),
      ),
    );
  }

  StreamBuilder<String> buildFontValidator() {
    return StreamBuilder<String>(
      stream: _streamData(),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final currFontName = snapshot.data;
          print(currFontName);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _baseTestPhrase,
                key: _latinTextKey,
                style: _getFontTextStyle(currFontName),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
              Text(
                _czechTestPhrase,
                key: _czechTextKey,
                style: _getFontTextStyle(currFontName),
              ),
            ],
          );
        }

        return Text('Loading ...');
      },
    );
  }
}

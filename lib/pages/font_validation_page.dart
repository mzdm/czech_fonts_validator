import 'dart:async';

import 'package:czech_fonts_validator/blocs/font_bloc.dart';
import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/models/language_fonts_model.dart';
import 'package:czech_fonts_validator/pages/result_page.dart';
import 'package:flutter/material.dart';
import 'package:google_language_fonts/google_fonts.dart';

part 'font_validation_helper.dart';

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
  final FontBloc fontBloc = FontBloc();

  TextStyle textStyle;
  bool shouldValidate = false;

  Stream<String> _streamData() async* {
    // final streamData = Stream.fromIterable(widget.fonts.fontNames);
    final fontNamesList = widget.fonts.fontNames.take(10).toList();

    var rendered = false;
    for (var i = 0; i < fontNamesList.length; i++) {
      // render font, then check sizes
      if (!rendered) {
        yield fontNamesList[i];
        rendered = true;
        --i;
        continue;
      }

      rendered = false;
      yield await checkNext(fontNamesList[i]);
    }
  }

  Future<String> checkNext(String fontName) async {
    await Future.delayed(Duration(milliseconds: 400));

    if (_areGoogleFontsRendered()) {
      final fontConfidence = _calcCzechFontConfidence(fontName);
      print(fontConfidence == Confidence.UNKWN
          ? '>>>>>>>>>>>>>>> $fontConfidence'
          : '> $fontConfidence');

      fontBloc.addCzechFont(
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
      final fontConfidence = _calcCzechFontConfidence(fontName);
      print(fontConfidence == Confidence.UNKWN
          ? '>>>>>>>>>>>>>>> $fontConfidence'
          : '> $fontConfidence');

      fontBloc.addCzechFont(
        CzechFont(fontName: fontName, confidence: fontConfidence),
      );
      return Future.value(fontName);
    }

    return null;
  }

  @override
  void dispose() {
    fontBloc.dispose();
    super.dispose();
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
          final totalScanLength = widget.fonts.fontNames.length;
          final currScanLength = fontBloc.getCurrStreamLength;

          if (currScanLength == 4) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ResultPage(fontBloc: fontBloc),
                ),
              ),
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '$currScanLength/$totalScanLength',
              ),
              Text(
                baseTestPhrase,
                key: _latinTextKey,
                style: getFontTextStyle(currFontName),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
              Text(
                czechTestPhrase,
                key: _czechTextKey,
                style: getFontTextStyle(currFontName),
              ),
            ],
          );
        }

        return Text('Loading ...');
      },
    );
  }
}

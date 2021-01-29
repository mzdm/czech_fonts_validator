import 'dart:async';

import 'package:czech_fonts_validator/blocs/font_bloc.dart';
import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/models/language_fonts_model.dart';
import 'package:czech_fonts_validator/pages/result_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_language_fonts/google_fonts.dart';

part 'font_validation_helper.dart';

final _czechTextKey = GlobalKey(debugLabel: 'czechTextKey');
final _latinTextKey = GlobalKey(debugLabel: 'latinTextKey');

final _czechTextKey2 = GlobalKey(debugLabel: 'czechTextKey2');
final _latinTextKey2 = GlobalKey(debugLabel: 'latinTextKey2');

final _czechTextKey3 = GlobalKey(debugLabel: 'czechTextKey3');
final _latinTextKey3 = GlobalKey(debugLabel: 'latinTextKey3');

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
  final shouldValidate = new ValueNotifier<bool>(false);
  FontBloc fontBloc;
  TextStyle textStyle;

  bool get validationState => shouldValidate?.value;

  void switchValidationState() => shouldValidate?.value = !validationState;

  @override
  void initState() {
    fontBloc = FontBloc();
    shouldValidate.addListener(() {
      if (!shouldValidate.value) {
        fontBloc?.dispose();
        fontBloc = FontBloc();
      }
    });
    super.initState();
  }

  Stream<String> _streamData(ScanBatch scanBatch) async* {
    // final streamData = Stream.fromIterable(widget.fonts.fontNames);
    final fontNamesList = <String>[];

    final allFontNamesList = widget.fonts.fontNames;
    final totalSize = allFontNamesList.length;
    final batchSize = totalSize ~/ 3;
    if (scanBatch == ScanBatch.FIRST) {
      fontNamesList.addAll(allFontNamesList.take(batchSize));
    } else if (scanBatch == ScanBatch.SECOND) {
      fontNamesList.addAll(allFontNamesList.getRange(batchSize, batchSize * 2));
    } else {
      fontNamesList.addAll(allFontNamesList.getRange(batchSize * 2, totalSize));
    }

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
      yield await checkNext(scanBatch, fontNamesList[i]);
      // final validated = await checkNext(fontNamesList[i]);
      // if (validated != null) {
      //   yield validated;
      // } else {
      //   continue;
      // }
      // rendered = false;
    }
  }

  Future<String> checkNext(ScanBatch scanBatch, String fontName) async {
    await Future.delayed(Duration(milliseconds: 400));

    if (_areGoogleFontsRendered(scanBatch)) {
      final fontConfidence = _calcCzechFontConfidence(scanBatch, fontName);
      print(fontConfidence == Confidence.UNKWN
          ? '>>>>>>>>>>>>>>> $fontConfidence'
          : '> $fontConfidence');

      fontBloc.addCzechFont(
        CzechFont(fontName: fontName, confidence: fontConfidence),
      );
      return Future.value(fontName);
    }

    int recheckDuration = 125;
    while (!_areGoogleFontsRendered(scanBatch)) {
      if (!validationState) return Future.value(null);

      await Future.delayed(Duration(milliseconds: recheckDuration));
      recheckDuration *= 2;

      if (recheckDuration == 2000) {
        print(
          'FAILED_CHECK: font \'$fontName\' was not successfully rendered in time',
        );
        return Future.value(null);
      }
    }

    if (_areGoogleFontsRendered(scanBatch)) {
      final fontConfidence = _calcCzechFontConfidence(scanBatch, fontName);
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
    shouldValidate.dispose();
    fontBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: shouldValidate,
      builder: (_, value, __) {
        return Scaffold(
          body: Center(
            child: !value
                ? Text('Press [PLAY] button to start validating Czech fonts')
                : buildFontValidators(),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: switchValidationState,
            tooltip: value ? 'Stop validating' : 'Start validating Czech fonts',
            child: Icon(value ? Icons.stop : Icons.play_arrow),
          ),
        );
      },
    );
  }

  Widget buildFontValidators() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final scanBatch in ScanBatch.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: buildStreamBuilder(scanBatch),
          ),
      ],
    );
  }

  StreamBuilder<String> buildStreamBuilder(ScanBatch scanBatch) {
    return StreamBuilder<String>(
      stream: _streamData(scanBatch),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final currFontName = snapshot.data;
          final totalScanLength = widget.fonts.fontNames.length;
          final currScanCounter = fontBloc.getCurrScanCounter;

          // TODO: move to another StreamBuilder
          if (currScanCounter > 25) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) {
                fontBloc.dispose();
                return Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (_) => ResultPage(fontBloc: fontBloc),
                    ))
                    .whenComplete(() => shouldValidate?.value = false);
              },
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (scanBatch == ScanBatch.FIRST)
                Text(
                  '$currScanCounter/$totalScanLength',
                ),
              Text(
                baseTestPhrase,
                key: getGlobalKey(scanBatch),
                style: getFontTextStyle(currFontName),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
              Text(
                czechTestPhrase,
                key: getGlobalKey(scanBatch, isLatin: false),
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

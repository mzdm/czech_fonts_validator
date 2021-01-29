import 'dart:async';

import 'package:czech_fonts_validator/blocs/font_bloc.dart';
import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/models/language_fonts_model.dart';
import 'package:czech_fonts_validator/pages/result_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
      if (!validationState) {
        fontBloc?.dispose();
        fontBloc = FontBloc();
        attachCounterListener();
      }
    });
    attachCounterListener();
    super.initState();
  }

  void attachCounterListener() {
    fontBloc.scanCounter.listen((state) {
      print(state);
      final totalScanLength = widget.fonts.fontNames.length;
      if (state > 10) {
        fontBloc.dispose();
        SchedulerBinding.instance.addPostFrameCallback(
          (_) {
            return Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (_) => ResultPage(fontBloc: fontBloc),
                ))
                .whenComplete(() => shouldValidate?.value = false);
          },
        );
      }
    });
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
    }
  }

  Future<String> checkNext(ScanBatch scanBatch, String fontName) async {
    await Future.delayed(Duration(milliseconds: 200));

    int recheckDuration = 256;
    while (!_areGoogleFontsRendered(scanBatch) &&
        _calcCzechFontConfidence(scanBatch) != null) {
      if (!validationState) return Future.value(null);

      await Future.delayed(Duration(milliseconds: recheckDuration));
      recheckDuration *= 2;

      if (recheckDuration == 2048) {
        print(
          'FAILED_CHECK: font \'$fontName\' was not successfully rendered in time',
        );
        return Future.value(null);
      }
    }

    if (_areGoogleFontsRendered(scanBatch)) {
      final confidence = _calcCzechFontConfidence(scanBatch, fontName);
      print('> $confidence');

      fontBloc.addCzechFont(
        CzechFont(fontName: fontName, confidence: confidence),
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
        buildScanCounter(),
        SizedBox(height: 75.0),
        for (final scanBatch in ScanBatch.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: buildFontValidator(scanBatch),
          ),
      ],
    );
  }

  StreamBuilder<int> buildScanCounter() {
    return StreamBuilder<int>(
      stream: fontBloc.scanCounter,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final totalScanLength = widget.fonts.fontNames.length;
          final currScanCounter = snapshot.data;
          return Text('$currScanCounter/$totalScanLength');
        }

        return Text('0/0');
      },
    );
  }

  StreamBuilder<String> buildFontValidator(ScanBatch scanBatch) {
    return StreamBuilder<String>(
      stream: _streamData(scanBatch),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final currFontName = snapshot.data;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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

        if (snapshot.hasError) {
          print(snapshot.error.toString());
          return Text('');
        }

        return Text('Loading ...');
      },
    );
  }
}

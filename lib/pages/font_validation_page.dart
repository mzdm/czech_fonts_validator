import 'dart:async';

import 'package:czech_fonts_validator/blocs/font_bloc.dart';
import 'package:czech_fonts_validator/helpers/validation_helper.dart';
import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/models/language_fonts_model.dart';
import 'package:czech_fonts_validator/pages/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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
  FontBloc fontBloc;

  final shouldValidate = new ValueNotifier<bool>(false);

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
      if (state == totalScanLength) {
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
    final fontNamesList = <String>[];

    final allFontNamesList = widget.fonts.fontNames;
    final totalSize = allFontNamesList.length;
    final batchSize = totalSize ~/ 3;
    if (scanBatch == ScanBatch.FIRST) {
      fontNamesList.addAll(allFontNamesList.sublist(0, batchSize));
    } else if (scanBatch == ScanBatch.SECOND) {
      fontNamesList.addAll(allFontNamesList.sublist(batchSize, batchSize * 2));
    } else {
      fontNamesList.addAll(allFontNamesList.sublist(batchSize * 2));
    }

    for (var i = 0; i < fontNamesList.length * 2; i++) {
      // firstly render font, then check the sizes
      if (i % 2 == 0) {
        yield fontNamesList[i ~/ 2];
      } else {
        yield await checkNext(scanBatch, fontNamesList[i ~/ 2]);
      }
    }
  }

  Future<String> checkNext(ScanBatch scanBatch, String fontName) async {
    final valHelper = ValidationHelper();

    await Future.delayed(Duration(milliseconds: 100));

    int recheckDuration = 64;
    while (!valHelper.areGoogleFontsRendered(scanBatch) ||
        valHelper.calcCzechFontConfidence(scanBatch) == null) {
      if (!validationState) return Future.value(null);

      await Future.delayed(Duration(milliseconds: recheckDuration));
      recheckDuration *= 2;

      if (recheckDuration == 2048) {
        print(
          'FAILED_CHECK: font \'$fontName\' was not successfully rendered in time',
        );
        fontBloc.increaseScanCounter();
        return Future.value(null);
      }
    }

    final confidence = valHelper.calcCzechFontConfidence(scanBatch, fontName);
    print('> $confidence');

    fontBloc.addCzechFont(
      scanBatch,
      CzechFont(fontName: fontName, confidence: confidence),
    );
    return Future.value(fontName);
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
    final valHelper = ValidationHelper();

    return StreamBuilder<String>(
      stream: _streamData(scanBatch),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final currFontName = snapshot.data;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                ValidationHelper.latinPhrase,
                key: valHelper.getGlobalKey(scanBatch),
                style: valHelper.getFontTextStyle(currFontName),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
              Text(
                ValidationHelper.czechPhrase,
                key: valHelper.getGlobalKey(scanBatch, isLatin: false),
                style: valHelper.getFontTextStyle(currFontName),
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

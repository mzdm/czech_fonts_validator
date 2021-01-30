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

  final valHelper = ValidationHelper();

  List<String> get allFontNamesList => widget.fonts.fontNames;

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
      if (state == allFontNamesList.length) {
        fontBloc?.dispose();
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

  Stream<String> validationStream(ScanBatch scanBatch) async* {
    final fontNamesList = <String>[]
      ..addAll(valHelper.getFontBatch(scanBatch, allFontNamesList));

    for (var i = 0; i < fontNamesList.length * 2; i++) {
      // firstly render font, then check the sizes
      if (i % 2 == 0) {
        yield fontNamesList[i ~/ 2];
      } else {
        yield await validate(scanBatch, fontNamesList[i ~/ 2]);
      }
    }
  }

  Future<String> validate(ScanBatch scanBatch, String fontName) async {
    await Future.delayed(Duration(milliseconds: 100));

    int recheckDur = 64;
    while (!valHelper.isFontRendered(scanBatch) ||
        valHelper.calcFontConfidence(scanBatch) == null) {
      if (!validationState) return Future.value(null);

      await Future.delayed(Duration(milliseconds: recheckDur));
      recheckDur *= 2;

      if (recheckDur == 2048) {
        print(
          'FAILED_CHECK: font \'$fontName\' was not successfully rendered in time',
        );
        fontBloc.increaseScanCounter();
        return Future.value(null);
      }
    }

    final confidence = valHelper.calcFontConfidence(scanBatch, fontName);
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
          final totalScanLength = allFontNamesList.length;
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
      stream: validationStream(scanBatch),
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

import 'dart:async';

import 'package:czech_fonts_validator/blocs/font_bloc.dart';
import 'package:czech_fonts_validator/helpers/validation_helper.dart';
import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/models/language_fonts_model.dart';
import 'package:czech_fonts_validator/pages/result_page.dart';
import 'package:czech_fonts_validator/service/service.dart';
import 'package:czech_fonts_validator/widgets/custom_appbar.dart';
import 'package:czech_fonts_validator/widgets/display_status_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;

class FontValidationPage extends StatefulWidget {
  @override
  _FontValidationPageState createState() => _FontValidationPageState();
}

class _FontValidationPageState extends State<FontValidationPage> {
  FontBloc fontBloc;

  LanguageFonts fontsToValidate;

  final valHelper = ValidationHelper();

  final service = Service(httpClient: http.Client());

  List<String> get allFontNamesList => fontsToValidate?.fontNames ?? [];

  final shouldValidate = new ValueNotifier<bool>(false);

  bool get validationState => shouldValidate?.value;

  void switchValidationState() => shouldValidate?.value = !validationState;

  final isSlowMode = new ValueNotifier<bool>(true);

  bool get slowModeState => isSlowMode?.value;

  void switchSlowModeState(bool value) {
    if (value == slowModeState) {
      isSlowMode?.value = !slowModeState;
    } else {
      isSlowMode?.value = value;
    }
  }

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
      if (validationState == true && state == allFontNamesList.length) {
        fontBloc?.dispose();
        SchedulerBinding.instance.addPostFrameCallback(
          (_) => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => ResultPage(fontBloc: fontBloc)),
              (_) => false),
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
    final initWaitDur = slowModeState ? 400 : 100;
    await Future.delayed(Duration(milliseconds: initWaitDur));

    int recheckDur = 64;
    while (!valHelper.isFontRendered(scanBatch) ||
        valHelper.calcFontConfidence(scanBatch) == null) {
      if (!validationState) return Future.value(null);

      await Future.delayed(Duration(milliseconds: recheckDur));
      recheckDur *= 2;

      if (recheckDur == 4096) {
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
  Widget build(BuildContext context) {
    return FutureBuilder<LanguageFonts>(
      future: service.fetchUnvalidatedFonts(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          fontsToValidate = snapshot.data;
          return buildPageContentSuccess();
        }

        if (snapshot.hasError) {
          return DisplayStatusMessage('Error: Couldn\'t retrieve data.');
        }

        return DisplayStatusMessage('Retrieving data ...');
      },
    );
  }

  ValueListenableBuilder<bool> buildPageContentSuccess() {
    return ValueListenableBuilder<bool>(
      valueListenable: shouldValidate,
      builder: (_, shouldValidateValue, __) {
        return Scaffold(
          appBar: buildCustomAppBar(),
          body: Center(
            child: !shouldValidateValue
                ? Text('Press [PLAY] button to start validating Czech fonts')
                : buildFontValidators(),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: switchValidationState,
            tooltip: shouldValidateValue
                ? 'Stop validating'
                : 'Start validating Czech fonts',
            child: Icon(shouldValidateValue ? Icons.stop : Icons.play_arrow),
          ),
        );
      },
    );
  }

  AppBar buildCustomAppBar() {
    return customAppBar(
      context,
      actions: <Widget>[
        Tooltip(
          message:
              'It is recommended to have Slow Mode turned on on the first run '
              'because some fonts may not be fetched and displayed correctly in time',
          child: Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: isSlowMode,
                builder: (_, slowModeValue, __) {
                  return Switch.adaptive(
                    value: slowModeValue,
                    onChanged: switchSlowModeState,
                  );
                },
              ),
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => switchSlowModeState(slowModeState),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15.0),
                      child: Text(
                        'Slow Mode',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
          final screenSize = MediaQuery?.of(context)?.size?.width ?? 0;
          final isScreenSmall = screenSize < 780;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                ValidationHelper.latinPhrase,
                key: valHelper.getGlobalKey(scanBatch),
                style: valHelper.getFontTextStyle(
                  currFontName,
                  fontSize: isScreenSmall ? 12.0 : null,
                ),
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
              Text(
                ValidationHelper.czechPhrase,
                key: valHelper.getGlobalKey(scanBatch, isLatin: false),
                style: valHelper.getFontTextStyle(
                  currFontName,
                  fontSize: isScreenSmall ? 12.0 : null,
                ),
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

  @override
  void dispose() {
    shouldValidate.dispose();
    isSlowMode.dispose();
    fontBloc.dispose();
    super.dispose();
  }
}

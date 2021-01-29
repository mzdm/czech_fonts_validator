import 'package:czech_fonts_validator/blocs/font_bloc.dart';
import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:flutter/material.dart';
import 'package:google_language_fonts/google_fonts.dart';

final _czechTextKey = GlobalKey(debugLabel: 'czechTextKey');
final _latinTextKey = GlobalKey(debugLabel: 'latinTextKey');

final _czechTextKey2 = GlobalKey(debugLabel: 'czechTextKey2');
final _latinTextKey2 = GlobalKey(debugLabel: 'latinTextKey2');

final _czechTextKey3 = GlobalKey(debugLabel: 'czechTextKey3');
final _latinTextKey3 = GlobalKey(debugLabel: 'latinTextKey3');

class ValidationHelper {
  static const latinPhrase = 'Prilis zlutoucky kun upel dabelske o';
  static const czechPhrase = 'Příliš žlutoučký kůň úpěl dábelské ó';
  static const czechPhraseFull = 'Příliš žluťoučký kůň úpěl ďábelské ó';

  GlobalKey getGlobalKey(
    ScanBatch scanBatch, {
    bool isLatin = true,
  }) {
    switch (scanBatch) {
      case ScanBatch.FIRST:
        return isLatin ? _latinTextKey : _czechTextKey;
      case ScanBatch.SECOND:
        return isLatin ? _latinTextKey2 : _czechTextKey2;
      default:
        return isLatin ? _latinTextKey3 : _czechTextKey3;
    }
  }

  TextStyle getFontTextStyle(String fontName, {double fontSize = 18.0}) =>
      GoogleFonts.getFont(fontName).copyWith(fontSize: fontSize);

  bool areGoogleFontsRendered(ScanBatch scanBatch) {
    final valHelper = ValidationHelper();

    final styleBase =
        (valHelper.getGlobalKey(scanBatch).currentContext?.widget as Text)
            ?.style;
    final styleCzech = (valHelper
            .getGlobalKey(scanBatch, isLatin: false)
            .currentContext
            ?.widget as Text)
        ?.style;

    if (styleBase == null || styleCzech == null) return false;
    return true;
  }

  Confidence calcCzechFontConfidence(ScanBatch scanBatch, [String fontName]) {
    Size sizeBase;
    Size sizeCzech;

    try {
      sizeBase = getGlobalKey(scanBatch).currentContext?.size;
      sizeCzech = getGlobalKey(scanBatch, isLatin: false).currentContext?.size;
    } catch (e) {
      return null;
    }

    final baseWidth = sizeBase.width;
    final baseHeight = sizeBase.height;

    final czechWidth = sizeCzech.width;
    final czechHeight = sizeCzech.height;

    final relativeWidthDiff = (czechWidth - baseWidth) / baseWidth;
    final relativeHeightDiff = (czechHeight - baseHeight) / baseHeight;

    if (fontName != null) {
      print(
        '\n$fontName:   Δw = $relativeWidthDiff  |  Δh: = $relativeHeightDiff  ${(getGlobalKey(scanBatch).currentContext?.widget as Text)?.style?.fontFamily}',
      );
    }

    // probably invisible characters
    if (baseWidth == 0 ||
        baseHeight == 0 ||
        czechWidth == 0 ||
        czechHeight == 0) return Confidence.LOWEST;

    // highly probable that it is valid Czech font
    if (sizeBase == sizeCzech) return Confidence.HIGHEST;

    // very high difference, contains unknown characters
    if (relativeWidthDiff.abs() >= 0.5 || relativeHeightDiff.abs() >= 0.5)
      return Confidence.LOWEST;
    if (relativeHeightDiff.abs() >= 0.35) return Confidence.LOW;

    // very unlikely that sentence in Czech will be shorter or smaller
    if (relativeWidthDiff < -0.1) return Confidence.LOWEST;
    if (relativeWidthDiff < -0.007) return Confidence.LOW;
    if (relativeWidthDiff < -0.005) return Confidence.MEDIUM;

    // very unlikely that sentence in Czech will be smaller
    if (relativeHeightDiff < -0.5) return Confidence.LOWEST;
    if (relativeHeightDiff < -0.05) return Confidence.LOW;

    if (relativeWidthDiff <= 0.005) return Confidence.HIGHEST;
    if (relativeWidthDiff <= 0.008) return Confidence.HIGH;
    if (relativeWidthDiff <= 0.01) return Confidence.MEDIUM;
    if (relativeWidthDiff <= 0.05) return Confidence.LOW;
    if (relativeWidthDiff <= 0.09) return Confidence.LOWEST;

    return Confidence.UNKWN;
  }
}
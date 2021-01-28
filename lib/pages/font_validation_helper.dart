part of 'font_validation_page.dart';

const baseTestPhrase = 'Prilis zlutoucky kun upel dabelske o';
const czechTestPhrase = 'Příliš žlutoučký kůň úpěl dábelské ó';
const czechTestPhraseFull = 'Příliš žluťoučký kůň úpěl ďábelské ó';

TextStyle getFontTextStyle(String fontName, {double fontSize = 18.0}) =>
    GoogleFonts.getFont(fontName).copyWith(fontSize: fontSize);

bool _areGoogleFontsRendered() {
  final styleBase = (_latinTextKey.currentContext?.widget as Text)?.style;
  final styleCzech = (_czechTextKey.currentContext?.widget as Text)?.style;

  if (styleBase == null || styleCzech == null) return false;
  return true;
}

Confidence _calcCzechFontConfidence(String fontName) {
  final sizeBase = _latinTextKey.currentContext.size;
  final sizeCzech = _czechTextKey.currentContext.size;

  final baseWidth = sizeBase.width;
  final baseHeight = sizeBase.height;

  final czechWidth = sizeCzech.width;
  final czechHeight = sizeCzech.height;

  final relativeWidthDiff = (czechWidth - baseWidth) / baseWidth;
  final relativeHeightDiff = (czechHeight - baseHeight) / baseHeight;

  print('\n$fontName:   Δw = $relativeWidthDiff  |  Δh: = $relativeHeightDiff');

  // probably invisible characters
  if (baseWidth == 0 || baseHeight == 0 || czechWidth == 0 || czechHeight == 0)
    return Confidence.LOWEST;

  // highly probable that it is valid Czech font
  if (sizeBase == sizeCzech) return Confidence.HIGHEST;

  // very high difference, contains unknown characters
  if (relativeWidthDiff.abs() >= 1 || relativeHeightDiff.abs() >= 1)
    return Confidence.LOWEST;
  if (relativeWidthDiff.abs() > 0.5 || relativeHeightDiff.abs() >= 0.5)
    return Confidence.LOW;
  if (relativeWidthDiff.abs() > 0.35 || relativeHeightDiff.abs() >= 0.35)
    return Confidence.MEDIUM;

  // very unlikely that sentence in Czech will be shorter
  if (relativeWidthDiff < -0.05) return Confidence.LOW;

  if (relativeWidthDiff <= 0.005) return Confidence.HIGHEST;
  if (relativeWidthDiff <= 0.014) return Confidence.HIGH;
  if (relativeWidthDiff <= 0.023) return Confidence.MEDIUM;
  if (relativeWidthDiff <= 0.05) return Confidence.LOW;
  if (relativeWidthDiff <= 0.09) return Confidence.LOWEST;

  // print('>$fontName:   Δw = $relativeWidthDiff  |  Δh: = $relativeHeightDiff  ${(_latinTextKey.currentContext?.widget as Text)?.style.toString()}');
  return Confidence.UNKWN;
}

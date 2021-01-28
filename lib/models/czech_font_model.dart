import 'package:flutter/foundation.dart';

enum Confidence { UNKWN, ANY, HIGHEST, HIGH, MEDIUM, LOW, LOWEST }

class CzechFont {
  final String fontName;
  final Confidence confidence;

  const CzechFont({
    @required this.fontName,
    @required this.confidence,
  });

  factory CzechFont.fromJson(Map<String, dynamic> json) => CzechFont(
        fontName: json['fontName'],
        confidence: json['confidence'],
      );

  Map<String, dynamic> toJson() => {
        'fontName': fontName,
        'confidence': confidence,
      };

  @override
  String toString() =>
      'CzechFont{fontName: $fontName, confidence: $confidence}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CzechFont &&
          runtimeType == other.runtimeType &&
          fontName == other.fontName &&
          confidence == other.confidence;

  @override
  int get hashCode => fontName.hashCode ^ confidence.hashCode;
}

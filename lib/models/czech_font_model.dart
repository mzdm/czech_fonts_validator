import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum Confidence { ANY, HIGHEST, HIGH, MEDIUM, LOW, LOWEST }

class CzechFont extends Equatable {
  final String fontName;
  final Confidence confidence;

  const CzechFont({
    required this.fontName,
    required this.confidence,
  });

  static CzechFont fromJson(Map<String, dynamic> json) => CzechFont(
        fontName: json['fontName'],
        confidence: _getConfidenceFromJson(json['confidence']),
      );

  Map<String, dynamic> toJson() => {
        'fontName': fontName,
        'confidence': describeEnum(confidence),
      };

  static Confidence _getConfidenceFromJson(String val) {
    for (final confidence in Confidence.values) {
      if (val == describeEnum(confidence)) {
        return confidence;
      }
    }
    return Confidence.ANY;
  }

  @override
  String toString() =>
      'CzechFont{fontName: $fontName, confidence: $confidence}';

  @override
  List<Object> get props => [fontName, confidence];
}

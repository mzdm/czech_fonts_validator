import 'package:equatable/equatable.dart';

class LanguageFonts extends Equatable {
  final String langName;
  final List<String> fontNames;

  const LanguageFonts({
    required this.langName,
    required this.fontNames,
  });

  factory LanguageFonts.fromJson(Map<String, dynamic> json) => LanguageFonts(
        langName: json['langName'],
        fontNames: List<String>.from(json['fontNames'].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        'langName': langName,
        'fontNames': List<dynamic>.from(fontNames.map((x) => x)),
      };

  @override
  List<Object> get props => [langName, fontNames];
}

import 'dart:convert';

import 'package:czech_fonts_validator/models/language_fonts_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Service {
  const Service({
    @required http.Client httpClient,
  }) : _httpClient = httpClient;

  final http.Client _httpClient;

  static const _baseUrl =
      'https://raw.githubusercontent.com/mzdm/google-language-fonts-flutter/dev-1.0.0/generator/lang_font_subsets/fonts.json';
  static const _langLookupVal = 'LatinExt';

  Future<LanguageFonts> fetchBaseFonts() async {
    final response = await _httpClient.get(_baseUrl);

    if (response.statusCode != 200) {
      throw (response?.toString());
    }

    final responseData = jsonDecode(response.body);

    LanguageFonts lookupLanguageFonts;
    for (final element in (responseData as List)) {
      try {
        final languageFonts = LanguageFonts.fromJson(element);
        if (languageFonts.langName == _langLookupVal) {
          lookupLanguageFonts = languageFonts;
          break;
        }
      } catch (e) {
        print(e);
      }
    }
    _httpClient.close();

    return lookupLanguageFonts;
  }
}

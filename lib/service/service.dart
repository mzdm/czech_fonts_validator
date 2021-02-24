import 'dart:convert';

import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/models/language_fonts_model.dart';
import 'package:http/http.dart' as http;

class Service {
  const Service({
    required http.Client httpClient,
  }) : _httpClient = httpClient;

  final http.Client _httpClient;

  static const _baseUrlValidated =
      'https://raw.githubusercontent.com/mzdm/czech_fonts/master/czech_fonts.json';

  static const _baseUrlUnvalidated =
      'https://raw.githubusercontent.com/mzdm/google-language-fonts-flutter/master/generator/lang_font_subsets/fonts.json';
  static const _langLookupVal = 'LatinExt';

  Future<List<CzechFont>> fetchValidatedFonts() async {
    final response = await _httpClient.get(_getUri(_baseUrlValidated));

    if (response.statusCode != 200) {
      throw (response.toString());
    }

    final responseData = jsonDecode(response.body);

    final czechFontsList = <CzechFont>[];
    for (final element in (responseData as List)) {
      try {
        final czechFont = CzechFont.fromJson(element);
        czechFontsList.add(czechFont);
      } catch (e) {
        print(e);
      }
    }
    _httpClient.close();

    return czechFontsList;
  }

  Future<LanguageFonts>? fetchUnvalidatedFonts() async {
    final response = await _httpClient.get(_getUri(_baseUrlUnvalidated));

    if (response.statusCode != 200) {
      throw (response.toString());
    }

    final responseData = jsonDecode(response.body);

    LanguageFonts? lookupLanguageFonts;
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

    return Future.value(lookupLanguageFonts);
  }

  Uri _getUri(String url) => Uri.parse(url);
}

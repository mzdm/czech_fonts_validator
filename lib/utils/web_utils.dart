import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:czech_fonts_validator/utils/utils.dart' as base;
import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:flutter/material.dart';

class Utils extends base.Utils {
  @override
  void downloadDataAsJson(
    BuildContext context, {
    required List<CzechFont> data,
  }) {
    try {
      final jsonData = jsonEncode(data.map((e) => e.toJson()).toList());
      final utfEncoded = utf8.encode(jsonData);
      final blob = html.Blob([utfEncoded]);
      js.context.callMethod("webSaveAs", [blob, "czech_fonts.json"]);
    } catch (e) {
      print(e);
      showSnackBar(context, e.toString());
    }
  }
}

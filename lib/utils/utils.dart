import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static const _srcUrl = 'https://github.com/mzdm/czech_fonts_validator';

  /// Opens the given [url] in a browser, on web in the new tab.
  void launchUrl(
    BuildContext context, {
    String url = _srcUrl,
  }) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      showSnackBar(context, 'Error: Can not open the website \'$url\'.');
    }
  }

  void copyPlainData(
    BuildContext context, {
    @required List<CzechFont> data,
    @required Confidence confidence,
  }) {
    final filtered = data
        .where((e) {
          if (confidence == Confidence.ANY) return true;
          return e.confidence == confidence;
        })
        .map((e) => e.fontName)
        .toList()
        .join('\n');
    Clipboard.setData(ClipboardData(text: filtered));

    showSnackBar(
      context,
      'Fonts with $confidence were copied to the clipboard.',
    );
  }

  void downloadDataAsJson(
    BuildContext context, {
    @required List<CzechFont> data,
  }) {
    throw ('Method called on unsupported platform');
  }

  void showSnackBar(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

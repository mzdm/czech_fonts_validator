import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static const _srcUrl = 'https://github.com/mzdm/czech_fonts_validator';

  /// Opens the given [url] in a browser, on web in the new tab.
  static void launchUrl(
    BuildContext context, {
    String url = _srcUrl,
  }) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Can not open the website \'$url\'.')),
      );
    }
  }
}

import 'package:czech_fonts_validator/pages/font_validation_page.dart';
import 'package:czech_fonts_validator/service/service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/language_fonts_model.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final service = Service(httpClient: http.Client());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<LanguageFonts>(
        future: service.fetchBaseFonts(),
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            print('fetched font data');
            return FontValidationPage(fonts: snapshot.data);
          }

          if (snapshot.hasError) {
            return buildPageContent('Error: Couldn\'t retrieve data.');
          }

          return buildPageContent('Retrieving data ...');
        },
      ),
    );
  }

  Scaffold buildPageContent(String text) {
    return Scaffold(
      body: Center(
        child: Text(text),
      ),
    );
  }
}

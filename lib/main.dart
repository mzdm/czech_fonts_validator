import 'package:czech_fonts_validator/src/font_validation_page.dart';
import 'package:czech_fonts_validator/src/language_fonts_model.dart';
import 'package:czech_fonts_validator/src/service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final service = Service(httpClient: http.Client());

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<LanguageFonts>(
        future: service.retrieveFonts(),
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            print('font data retrieved');
            return FontValidationPage(fonts: snapshot.data);
          }

          if (snapshot.hasError) {
            return buildScaffold('Error: Couldn\'t retrieve data.');
          }

          return buildScaffold('Retrieving data ...');
        },
      ),
    );
  }

  Scaffold buildScaffold(String text) {
    return Scaffold(
      body: Center(
        child: Text(text),
      ),
    );
  }
}

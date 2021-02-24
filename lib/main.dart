import 'package:czech_fonts_validator/models/czech_font_model.dart';
import 'package:czech_fonts_validator/pages/font_validation_page.dart';
import 'package:czech_fonts_validator/pages/result_page.dart';
import 'package:czech_fonts_validator/service/service.dart';
import 'package:czech_fonts_validator/widgets/display_status_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'blocs/font_bloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final service = Service(httpClient: http.Client());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FutureBuilder<List<CzechFont>>(
        future: service.fetchValidatedFonts(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final fontBloc = FontBloc(initialFontsList: snapshot.data);
            return ResultPage(fontBloc: fontBloc);
          }

          if (snapshot.hasError) {
            return FontValidationPage();
          }

          return DisplayStatusMessage('Retrieving data ...');
        },
      ),
    );
  }
}

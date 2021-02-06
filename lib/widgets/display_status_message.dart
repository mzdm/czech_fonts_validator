import 'package:czech_fonts_validator/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';

class DisplayStatusMessage extends StatelessWidget {
  final String text;

  const DisplayStatusMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(),
      body: Center(
        child: Text(text),
      ),
    );
  }
}

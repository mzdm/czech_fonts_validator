import 'package:flutter/material.dart';

AppBar customAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    elevation: 0.0,
    iconTheme: IconThemeData(color: Colors.black87),
  );
}

import 'package:flutter/material.dart';

class HelperMethods {
  static showSnackbar(BuildContext context, content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: content),
    );
  }
}

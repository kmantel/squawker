import 'package:flutter/material.dart';

Size calcTextSizeWithStyle(BuildContext context, String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaleFactor: MediaQuery.of(context).textScaleFactor,
  )..layout();
  return textPainter.size;
}

Size calcTextSize(BuildContext context, String text) {
  return calcTextSizeWithStyle(context, text, DefaultTextStyle.of(context).style);
}



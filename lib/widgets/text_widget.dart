import 'package:flutter/material.dart';
import 'dart:math';

class SentText extends StatelessWidget {
  const SentText({
    Key key,
    @required this.sentText,
    @required this.color,
    @required this.fontSize,
  }) : super(key: key);

  final String sentText;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: Text(
        sentText,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

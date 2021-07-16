import 'package:flutter/material.dart';

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
    return Text(
      sentText,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
      ),
    );
  }
}

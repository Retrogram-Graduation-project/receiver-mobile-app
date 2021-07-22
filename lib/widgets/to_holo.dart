import 'package:flutter/material.dart';

class ToHolo extends StatelessWidget {
  final Widget widget;
  ToHolo(this.widget);
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    final List<Widget> _stackChildren = List.unmodifiable([
      Positioned(
        // top
        child: RotatedBox(
          quarterTurns: 2,
          child: Container(
            alignment: Alignment.center,
            child: widget,
            width: 150,
            height: 150,
          ),
        ),
        top: height / 4 - 75,
        left: width / 2 - 75,
      ),
      Positioned(
        // left
        child: RotatedBox(
          quarterTurns: 1,
          child: Container(
            alignment: Alignment.center,
            child: widget,
            width: 150,
            height: 150,
          ),
        ),
        top: height / 2 - 75,
        left: 0,
      ),
      Positioned(
        // right
        child: RotatedBox(
          quarterTurns: 3,
          child: Container(
            alignment: Alignment.center,
            child: widget,
            width: 150,
            height: 150,
          ),
        ),
        top: height / 2 - 75,
        right: 0,
      ),
      Positioned(
        // bottom
        child: Container(
          child: widget,
          width: 150,
          height: 150,
          alignment: Alignment.center,
        ),
        bottom: height / 4 - 75,
        left: width / 2 - 75,
      ),
    ]);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: width,
        height: height,
        child: Stack(
          children: _stackChildren,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

/// A Stateful widget that paints flutter logo using [CustomPaint] and [Path].
class MyHomePage extends StatefulWidget {
  final paths = [
    ['m48.75 95.97-25.91-25.74 14.32-14.57 40.39 40.31z', Color(0xff02539a)],
    ['m22.52 70.25 25.68-25.68h28.87l-39.95 39.95z', Color(0xd745d1fd)],
    ['m.29 47.85 14.58 14.57 62.2-62.2h-29.02z', Color(0xff45d1fd)]
  ];
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool showBorder = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Transform.scale(
        scale: 2.0,
        child: GestureDetector(
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              child: Stack(
                children: widget.paths.map((e) {
                  return CustomPaint(
                      painter: MyPainter(parseSvgPath(e[0] as String), e[1] as Color,
                          showPath: showBorder));
                }).toList(),
              ),
            ),
          ),
          behavior: HitTestBehavior.translucent,
          onTap: () {
            setState(() {
              // hide/show border
              showBorder = !showBorder;
            });
          },
        ),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final Path path;
  final Color color;
  final bool showPath;
  MyPainter(this.path, this.color, {this.showPath = true});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 4.0;
    canvas.drawPath(path, paint);
    if (showPath) {
      var border = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, border);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

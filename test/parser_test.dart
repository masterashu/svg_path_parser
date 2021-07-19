import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:svg_path_parser/svg_path_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests the scanner for correctly parses the input.
main() {
  final testingArea =
      Rect.fromCenter(center: Offset.zero, width: 15, height: 15);
  group('Testing paths from commands', () {
    group('test moveTo commands', () {
      test('test consecutive arguments act as lineTo commands.', () {
        // test relative path
        var expectedPath = Path()
          ..moveTo(2, 2)
          ..lineTo(5, 6)
          ..lineTo(6, 8);
        expect(
            parseSvgPath('M2,2 5,6, 6,8'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
        // test relative path
        expect(
            parseSvgPath('m2,2 3,4, 1,2'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
      });

      test('test moves', () {
        var expectedPath = Path()
          ..moveTo(1, 1)
          ..moveTo(2, 2)
          ..lineTo(3, 3)
          ..lineTo(4, 2);
        expect(
            parseSvgPath('M1,1M2,2L3,3L4,2'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
        expect(
            parseSvgPath('M1,1m1,1L3,3L4,2'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
      });
    });

    group('test lineTo commands', () {
      test('test lineTo absolute', () {
        var expectedPath = Path()
          ..moveTo(2, 2)
          ..lineTo(0, 4)
          ..lineTo(2, 6)
          ..lineTo(4, 4);
        expect(
            parseSvgPath('M2,2L0 4, 2,6, 4 4'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
      });

      test('test lineTo relative', () {
        var expectedPath = Path()
          ..moveTo(2, 2)
          ..lineTo(2, 6)
          ..lineTo(0, 4)
          ..lineTo(4, 4);
        expect(
            parseSvgPath('M2,2l0 4-2-2,4,0'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
      });

      group('test horizontal/vertical lineTo commands', () {
        test('test horizontal/vertocalLineTo absolute', () {
          var expectedPath = Path()
            ..moveTo(2, 2)
            ..lineTo(2, 4)
            ..lineTo(4, 4)
            ..lineTo(4, 2);
          expect(
              parseSvgPath('M2,2V4H4V2'),
              coversSameAreaAs(expectedPath,
                  areaToCompare: testingArea, sampleSize: 400));
        });

        test('test horizontal/vertocalLineTo relative', () {
          var expectedPath = Path()
            ..moveTo(2, 2)
            ..lineTo(2, 4)
            ..lineTo(4, 4)
            ..lineTo(4, 2);
          expect(
              parseSvgPath('M2,2v2h2v-2'),
              coversSameAreaAs(expectedPath,
                  areaToCompare: testingArea, sampleSize: 400));
        });
      });
    });

    group('test curveTo commands', () {
      test('test normal curveTo', () {
        var expectedPath = Path()
          ..moveTo(2, 2)
          ..cubicTo(3, 3, 6, 6, 4, 4);
        // test absolute
        expect(
            parseSvgPath('M2,2C3,3,6,6,4,4'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
        // test relative
        expect(
            parseSvgPath('M2 2c1 1 4 4 2 2'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
      });

      group('test chained curveTo', () {
        test('test chained curveTo', () {
          var expectedPath = Path()
            ..cubicTo(1, 1, 4, 3, 5, 5)
            ..cubicTo(3, 4, 4, 7, 8, 5);
          expect(
              parseSvgPath('C1,1,4,3,5,5, 3 4 4 7 8,5'),
              coversSameAreaAs(expectedPath,
                  areaToCompare: testingArea, sampleSize: 400));
        });

        test('test chained curveTo and smooth curveTo', () {
          var expectedPath = Path()
            ..cubicTo(1, 1, 4, 3, 5, 5)
            ..cubicTo(6, 7, 4, 7, 8, 5);
          expect(
              parseSvgPath('C1,1,4,3,5,5S 4 7 8,5'),
              coversSameAreaAs(expectedPath,
                  areaToCompare: testingArea, sampleSize: 400));
        });

        test('test smoothCurveTo takes current point as control point', () {
          var expectedPath = Path()
            ..moveTo(2, 2)
            ..cubicTo(2, 2, 3, 5, 2, 6);
          expect(
              parseSvgPath('M2,2 S3,5 2,6'),
              coversSameAreaAs(expectedPath,
                  areaToCompare: testingArea, sampleSize: 400));
        });
      });
    });

    group('test quadraticBezierTo commands', () {
      test('test normal quadraticBezier', () {
        var expectedPath = Path()
          ..moveTo(2, 2)
          ..quadraticBezierTo(5, 6, 4, 4);
        // test absolute
        expect(
            parseSvgPath('M2,2Q5,6,4,4'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
        // test relative
        expect(
            parseSvgPath('M2 2q 3 4 2 2'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
      });

      group('test chained quadraticBezier', () {
        test('test chained quadraticBezier', () {
          var expectedPath = Path()
            ..quadraticBezierTo(1, 1, 4, 3)
            ..quadraticBezierTo(3, 7, 8, 5);
          expect(
              parseSvgPath('Q1,1,4,3Q3,7 8,5'),
              coversSameAreaAs(expectedPath,
                  areaToCompare: testingArea, sampleSize: 400));
        });

        test('test chained quadraticBezier and smooth quadraticBezier', () {
          var expectedPath = Path()
            ..quadraticBezierTo(1, 3, 5, 5)
            ..quadraticBezierTo(9, 7, 8, 5);
          expect(
              parseSvgPath('Q1,3,5,5T8,5'),
              coversSameAreaAs(expectedPath,
                  areaToCompare: testingArea, sampleSize: 400));
        });
      });
    });

    group('test ellipticalArcTo commands', () {
      test('test ellipticalArtTo absolute', () {
        var expectedPath = Path()
          ..moveTo(0, 4)
          ..arcToPoint(Offset(7, 1),
              radius: Radius.elliptical(5, 8),
              rotation: 0.12,
              largeArc: true,
              clockwise: true);
        expect(
            parseSvgPath('M0,4A5,8,.12 1 1, 7,1'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
      });

      test('test ellipticalArtTo relative', () {
        var expectedPath = Path()
          ..moveTo(0, 0)
          ..arcToPoint(Offset(5, 5),
              radius: Radius.elliptical(11, 7), largeArc: true, clockwise: true)
          ..close();
        // Note: Make a check for out of range parameters:
        // https://www.w3.org/TR/SVG11/implnote.html#ArcOutOfRangeParameters
        expect(
            parseSvgPath('a11,7, 0 1 1, 5,5z'),
            coversSameAreaAs(expectedPath,
                areaToCompare: testingArea, sampleSize: 400));
      });
    });
  });

  group('Testing combination of relative and absolute commands', () {
    final testingArea =
        Rect.fromCenter(center: Offset.zero, width: 20, height: 20);

    group('Test Flag pattern on cubic curves', () {
      final testingArea =
          Rect.fromCenter(center: Offset.zero, width: 20, height: 20);
      group('test ellipticalArcTo commands', () {
        test('test ellipticalArtTo absolute', () {
          var expectedPath = Path()
            ..moveTo(0, 4)
            ..arcToPoint(Offset(7, 1),
                radius: Radius.elliptical(5, 8),
                rotation: 0.12,
                largeArc: true,
                clockwise: true);
          expect(
              parseSvgPath('M0,4A5,8,.12 11 7 1'),
              coversSameAreaAs(expectedPath,
                  areaToCompare: testingArea, sampleSize: 400));
        });

        test('test ellipticalArtTo relative', () {
          var expectedPath = Path()
            ..moveTo(0, 0)
            ..arcToPoint(Offset(5, 5),
                radius: Radius.elliptical(11, 7),
                largeArc: true,
                clockwise: true)
            ..close();
          // Note: Make a check for out of range parameters:
          // https://www.w3.org/TR/SVG11/implnote.html#ArcOutOfRangeParameters
          expect(
              parseSvgPath('a11,7, 0 115,5z'),
              coversSameAreaAs(expectedPath,
                  areaToCompare: testingArea, sampleSize: 400));
        });
      });
    });
  });

  group('Test square path on different combinations', () {
    test('Testing flags without any spaces', () {
      var expectedPath = Path()
        ..moveTo(0, 0)
        ..lineTo(0, 5)
        ..lineTo(5, 5)
        ..lineTo(5, 0)
        ..close();

      expect(
          parseSvgPath('M 0 0 V5 H5 V0z'),
          coversSameAreaAs(expectedPath,
              areaToCompare: testingArea, sampleSize: 400));
      expect(
          parseSvgPath('M0 0 v5 h5 V0z'),
          coversSameAreaAs(expectedPath,
              areaToCompare: testingArea, sampleSize: 400));
      expect(
          parseSvgPath('M0 0 V5 h5 v-5z'),
          coversSameAreaAs(expectedPath,
              areaToCompare: testingArea, sampleSize: 400));
      expect(
          parseSvgPath('M0 0 h5 V5 H0 z'),
          coversSameAreaAs(expectedPath,
              areaToCompare: testingArea, sampleSize: 400));
      expect(
          parseSvgPath('M0 0 v5 H5 v-5z'),
          coversSameAreaAs(expectedPath,
              areaToCompare: testingArea, sampleSize: 400));
    });
  });
}

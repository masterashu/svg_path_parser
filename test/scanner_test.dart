import 'package:string_scanner/string_scanner.dart';
import 'package:svg_path_parser/svg_path_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// Tests the scanner for correctly generating the tokens and throwing errors
main() {
  test("throws ArgumentError on null input", () {
    expect(() => Scanner(null), throwsArgumentError);
  });

  test("scan empty string", () {
    var scanner = Scanner('');
    expect(scanner.scan().type, TokenType.streamStart);
    expect(scanner.scan().type, TokenType.streamEnd);
  });

  group("All Commands are scanned correctly", () {
    group("closePath command", () {
      test("closePath command scanned correctly", () {
        var scanner = Scanner('Z,z')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.closePath, CoordinateType.absolute));
        expect(scanner.scan(),
            CommandToken(TokenType.closePath, CoordinateType.relative));
      });
    });

    group("moveTo command", () {
      test("moveTo command scanned correctly", () {
        var scanner = Scanner('M10,20')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.moveTo, CoordinateType.absolute));
      });

      test("relativeMoveTo command scanned correctly", () {
        var scanner = Scanner('m10,20')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.moveTo, CoordinateType.relative));
      });

      test("moveTo missing/incomplete args", () {
        var scanner = Scanner('m')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('m10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('m10,20,30')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
      });

      test("moveTo scan extra args", () {
        var scanner = Scanner('m1,1 2,4')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.moveTo, CoordinateType.relative));
        expect(scanner.scan(), ValueToken(TokenType.value, 1.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 1.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 2.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 4.0));
      });
    });

    group("lineTo command", () {
      test("lineTo command scanned correctly", () {
        var scanner = Scanner('L10,20')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.lineTo, CoordinateType.absolute));
      });

      test("relativeLineTo command scanned correctly", () {
        var scanner = Scanner('l10,20')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.lineTo, CoordinateType.relative));
      });

      test("lineTo missing/incomplete args", () {
        var scanner = Scanner('l')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('l10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('l10,20,30')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
      });

      test("lineTo scan extra args", () {
        var scanner = Scanner('l1,1 2,4')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.lineTo, CoordinateType.relative));
        expect(scanner.scan(), ValueToken(TokenType.value, 1.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 1.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 2.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 4.0));
      });
    });

    group("horizontalLineTo command", () {
      test("horizontalLineTo command scanned correctly", () {
        var scanner = Scanner('H10')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.horizontalLineTo, CoordinateType.absolute));
      });

      test("relativeHorizontalLineTo command scanned correctly", () {
        var scanner = Scanner('h10')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.horizontalLineTo, CoordinateType.relative));
      });

      test("horizontalTo missing/incomplete args", () {
        var scanner = Scanner('H')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('m10')..scan();
      });

      test("horizontalTo scan extra args", () {
        var scanner = Scanner('h1,4')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.horizontalLineTo, CoordinateType.relative));
        expect(scanner.scan(), ValueToken(TokenType.value, 1.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 4.0));
      });
    });

    group("verticalLineTo command", () {
      test("verticalLineTo command scanned correctly", () {
        var scanner = Scanner('V10')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.verticalLineTo, CoordinateType.absolute));
      });

      test("relativeVerticalLineTo command scanned correctly", () {
        var scanner = Scanner('v10')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.verticalLineTo, CoordinateType.relative));
      });

      test("verticalTo missing/incomplete args", () {
        var scanner = Scanner('V')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('m10')..scan();
      });

      test("verticalTo scan extra args", () {
        var scanner = Scanner('v1,4')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.verticalLineTo, CoordinateType.relative));
        expect(scanner.scan(), ValueToken(TokenType.value, 1.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 4.0));
      });
    });

    group("curveTo command", () {
      test("curveTo command scanned correctly", () {
        var scanner = Scanner('C10,10 20,20, 15,0')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.curveTo, CoordinateType.absolute));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 20.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 20.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 15.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 0.0));
      });

      test("relativeCurveTo command scanned correctly", () {
        var scanner = Scanner('c10,10 5,-5, -10,5')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.curveTo, CoordinateType.relative));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 5.0));
        expect(scanner.scan(), ValueToken(TokenType.value, -5.0));
        expect(scanner.scan(), ValueToken(TokenType.value, -10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 5.0));
      });

      test("curveTo missing/incomplete args", () {
        var scanner = Scanner('C 10,10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('C 10,10 5,5')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('C 10,10, 20,20, 10,50, 10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
      });

      test("curveTo scan extra args", () {
        var scanner = Scanner('C 10,10, 20,20, 10,50, 20,20, 10,50, 34,55')
          ..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.curveTo, CoordinateType.absolute));
      });
    });

    group("smoothCurveTo command", () {
      test("smoothCurveTo command scanned correctly", () {
        var scanner = Scanner('S10,10 20,20')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.smoothCurveTo, CoordinateType.absolute));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 20.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 20.0));
      });

      test("relativeSmoothCurveTo command scanned correctly", () {
        var scanner = Scanner('s10,10 5,5')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.smoothCurveTo, CoordinateType.relative));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 5.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 5.0));
      });
      test("smoothCurveTo missing/incomplete args", () {
        var scanner = Scanner('s 10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('s 10,10 5')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('S 10,10, 20,20, 10,50, 10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
      });

      test("smoothCurveTo scan extra args", () {
        var scanner = Scanner('S 10,10, 20,20, 10,50, 20,20')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.smoothCurveTo, CoordinateType.absolute));
      });
    });

    group("quadraticBezierCurveTo command", () {
      test("quadraticBezierCurveTo command scanned correctly", () {
        var scanner = Scanner('Q10,10 20,20')..scan();
        expect(
            scanner.scan(),
            CommandToken(
                TokenType.quadraticBezierCurveTo, CoordinateType.absolute));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 20.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 20.0));
      });

      test("relativeQuadraticBezierCurveTo command scanned correctly", () {
        var scanner = Scanner('q10,-5, -10,5')..scan();
        expect(
            scanner.scan(),
            CommandToken(
                TokenType.quadraticBezierCurveTo, CoordinateType.relative));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, -5.0));
        expect(scanner.scan(), ValueToken(TokenType.value, -10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 5.0));
      });

      test("quadraticBezierCurveTo missing/incomplete args", () {
        var scanner = Scanner('q 10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('q 10,10 5')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('Q 10,10, 20,20, 10,50, 10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
      });

      test("quadraticBezierCurveTo scan extra args", () {
        var scanner = Scanner('Q 10,10, 20,20, 10,50, 20,20')..scan();
        expect(
            scanner.scan(),
            CommandToken(
                TokenType.quadraticBezierCurveTo, CoordinateType.absolute));
      });
    });

    group("smoothQuadraticBezierCurveTo command", () {
      test("smoothQuadraticBezierCurveTo command scanned correctly", () {
        var scanner = Scanner('T10,10')..scan();
        expect(
            scanner.scan(),
            CommandToken(TokenType.smoothQuadraticBezierCurveTo,
                CoordinateType.absolute));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
      });

      test("relativeSmoothQuadraticBezierCurveTo command scanned correctly",
          () {
        var scanner = Scanner('t10,5')..scan();
        expect(
            scanner.scan(),
            CommandToken(TokenType.smoothQuadraticBezierCurveTo,
                CoordinateType.relative));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 5.0));
      });

      test("smoothQuadraticBezierCurveTo missing/incomplete args", () {
        var scanner = Scanner('t 10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('T 10,10 5')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
      });

      test("smoothQuadraticBezierCurveTo scan extra args", () {
        var scanner = Scanner('T 10,10, 20,20')..scan();
        expect(
            scanner.scan(),
            CommandToken(TokenType.smoothQuadraticBezierCurveTo,
                CoordinateType.absolute));
      });
    });

    group("ellipticalArcTo command", () {
      test("ellipticalArcTo command scanned correctly", () {
        var scanner = Scanner('A10,10 20, 1,0 20,10')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.ellipticalArcTo, CoordinateType.absolute));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 20.0));
        expect(scanner.scan(), ValueToken(TokenType.flag, 1));
        expect(scanner.scan(), ValueToken(TokenType.flag, 0));
        expect(scanner.scan(), ValueToken(TokenType.value, 20.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
      });

      test("relativeEllipticalArcTo command scanned correctly", () {
        var scanner = Scanner('a10,10 5 0,0 -5,5')..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.ellipticalArcTo, CoordinateType.relative));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 5.0));
        expect(scanner.scan(), ValueToken(TokenType.flag, 0));
        expect(scanner.scan(), ValueToken(TokenType.flag, 0));
        expect(scanner.scan(), ValueToken(TokenType.value, -5.0));
        expect(scanner.scan(), ValueToken(TokenType.value, 5.0));
      });

      test("ellipticalArcTo missing/incomplete args", () {
        var scanner = Scanner('a 10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('a 10,10 5')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
        scanner = Scanner('a10,10, 20 0,1 10 50,10 10')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
      });

      test("wrong flag argument", () {
        var scanner = Scanner('a10,10 5 0.1,1 -5')..scan();
        expect(() => scanner.scan(),
            throwsA(isInstanceOf<StringScannerException>()));
      });

      test("ellipticalArcTo scan extra args", () {
        var scanner = Scanner('A 10,10, 20,0,1 10,50 5,60, 10,1,1 16,10')
          ..scan();
        expect(scanner.scan(),
            CommandToken(TokenType.ellipticalArcTo, CoordinateType.absolute));
      });
    });
  });

  group("test correct scan of commas", () {
    test("error on consecutive comma bewteen values", () {
      var scanner = Scanner('M 10,,10')..scan();
      expect(() => scanner.scan(),
          throwsA(isInstanceOf<StringScannerException>()));
    });
    test("allow consecutive comma bewteen/before commands", () {
      var scanner = Scanner('M10,10,,,z')..scan();
      expect(scanner.scan(),
          CommandToken(TokenType.moveTo, CoordinateType.absolute));
    });
    test("allow consecutive comma at the end", () {
      var scanner = Scanner('M10,10,,,,')..scan();
      expect(scanner.scan(),
          CommandToken(TokenType.moveTo, CoordinateType.absolute));
      expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
      expect(scanner.scan(), ValueToken(TokenType.value, 10.0));
      expect(scanner.scan(), Token(TokenType.streamEnd));
    });
  });
}

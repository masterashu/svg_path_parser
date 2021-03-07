import 'dart:ui';
import 'package:svg_path_parser/src/scanner.dart';
import 'package:svg_path_parser/src/tokens.dart';

/// A Parser that converts a SVG path to a [Path] object.
class Parser {
  /// Creates a new [Parser] object.
  ///
  /// [source] should not be null.
  Parser(source)
      : _scanner = Scanner(source),
        path = Path(),
        _initialPoint = Offset.zero,
        _currentPoint = Offset.zero,
        _lastCommandArgs = [];

  /// Last command Parsed
  late CommandToken _lastCommand;

  /// List of Arguments of Previous Command
  List<dynamic> _lastCommandArgs;

  /// The initial [Offset] where the [Path] object started from.
  Offset _initialPoint;

  /// The current [Offset] where the [Path] is currently at.
  Offset _currentPoint;

  /// The path object to be returned.
  Path path;

  /// The underlying [Scanner] which reads input source and emits [Token]s.
  final Scanner _scanner;

  /// Parses the SVG path.
  Path parse() {
    // Scan streamStart Token
    _parseStreamStart();

    while (_scanner.peek()!.type != TokenType.streamEnd) {
      _parseCommand();
    }

    _parseStreamEnd();

    return this.path;
  }

  /// Parses the stream start token.
  _parseStreamStart() {
    _scanner.scan();
  }

  /// Parses the stream end token.
  _parseStreamEnd() {
    _scanner.scan();
  }

  /// Parses a SVG path Command.
  _parseCommand() {
    Token token = _scanner.peek()!;
    // If extra arguments are encountered. Use the last command.
    if (!(token is CommandToken)) {
      // Subsequent pairs after first Move to are considered as implicit
      // Line to commands. https://www.w3.org/TR/SVG/paths.html#PathDataMovetoCommands
      if (_lastCommand.type == TokenType.moveTo) {
        token = CommandToken(TokenType.lineTo, _lastCommand.coordinateType);
      } else {
        token = _lastCommand;
      }
    } else {
      token = _scanner.scan()!;
    }

    switch (token.type) {
      case TokenType.moveTo:
        _parseMoveTo(token as CommandToken);
        return;
      case TokenType.closePath:
        _parseClosePath(token as CommandToken);
        return;
      case TokenType.lineTo:
        _parseLineTo(token as CommandToken);
        return;
      case TokenType.horizontalLineTo:
        _parseHorizontalLineTo(token as CommandToken);
        return;
      case TokenType.verticalLineTo:
        _parseVerticalLineTo(token as CommandToken);
        return;
      case TokenType.curveTo:
        _parseCurveTo(token as CommandToken);
        return;
      case TokenType.smoothCurveTo:
        _parseSmoothCurveTo(token as CommandToken);
        return;
      case TokenType.quadraticBezierCurveTo:
        _parseQuadraticBezierCurveTo(token as CommandToken);
        return;
      case TokenType.smoothQuadraticBezierCurveTo:
        _parseSmoothQuadraticBezierCurveTo(token as CommandToken);
        return;
      case TokenType.ellipticalArcTo:
        _parseEllipticalArcTo(token as CommandToken);
        return;
      default:
        return;
    }
  }

  /// Parses a [CommandToken] of type [TokenType.moveTo] and it's Argument [ValueToken]s.
  ///
  /// move-to-args: x, y            (absolute)
  /// move-to-args: dx, dy          (relative)
  _parseMoveTo(CommandToken commandToken) {
    var x = (_scanner.scan()! as ValueToken).value;
    var y = (_scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.moveTo(x as double, y as double);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeMoveTo(x as double, y as double);
      _currentPoint.translate(x, y);
    }
    // moveTo command reset the initial and current point
    _initialPoint = _currentPoint;

    _lastCommand = commandToken;
    _lastCommandArgs = [x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.closePath].
  _parseClosePath(CommandToken commandToken) {
    this.path.close();
    // closePath resets the current point to initial point.
    _currentPoint = _initialPoint;

    _lastCommand = commandToken;
    _lastCommandArgs.clear();
  }

  /// Parses a [CommandToken] of type [TokenType.lineTo] and it's Argument [ValueToken]s.
  ///
  /// line-to-args: x, y            (absolute)
  /// line-to-args: dx, dy          (relative)
  _parseLineTo(CommandToken commandToken) {
    var x = (_scanner.scan()! as ValueToken).value;
    var y = (_scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.lineTo(x as double, y as double);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeLineTo(x as double, y as double);
      _currentPoint.translate(x, y);
    }

    _lastCommand = commandToken;
    _lastCommandArgs = [x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.horizontalLineTo] and it's Argument [ValueToken]s.
  ///
  /// horizontal-line-to-args: x     (absolute)
  /// horizontal-line-to-args: dx    (relative)
  _parseHorizontalLineTo(CommandToken commandToken) {
    var h = (_scanner.scan()! as ValueToken).value;
    var y = _currentPoint.dy;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.lineTo(h as double, y);
      _currentPoint = Offset(h, y);
    } else {
      this.path.relativeLineTo(h as double, 0);
      _currentPoint.translate(h, 0);
    }

    _lastCommand = commandToken;
    _lastCommandArgs = [h];
  }

  /// Parses a [CommandToken] of type [TokenType.verticalLineTo] and it's Argument [ValueToken]s.
  ///
  /// vertical-line-to-args: y        (absolute)
  /// vertical-line-to-args: dy       (relative)
  _parseVerticalLineTo(CommandToken commandToken) {
    var v = (_scanner.scan()! as ValueToken).value;
    var x = _currentPoint.dx;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.lineTo(x, v as double);
      _currentPoint = Offset(x, v);
    } else {
      this.path.relativeLineTo(0, v as double);
      _currentPoint.translate(0, v);
    }

    _lastCommand = commandToken;
    _lastCommandArgs = [v];
  }

  /// Parses a [CommandToken] of type [TokenType.curveTo] and it's Argument [ValueToken]s.
  ///
  /// curve-to-args: x1,y1 x2,y2 x,y        (absolute)
  /// curve-to-args: dx1,dy1 dx2,dy2 dx,dy  (relative)
  _parseCurveTo(CommandToken commandToken) {
    var x1 = (_scanner.scan()! as ValueToken).value;
    var y1 = (_scanner.scan()! as ValueToken).value;
    var x2 = (_scanner.scan()! as ValueToken).value;
    var y2 = (_scanner.scan()! as ValueToken).value;
    var x = (_scanner.scan()! as ValueToken).value;
    var y = (_scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.cubicTo(x1 as double, y1 as double, x2 as double, y2 as double,
          x as double, y as double);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeCubicTo(x1 as double, y1 as double, x2 as double, y2 as double,
          x as double, y as double);
      _currentPoint.translate(x, y);
    }

    _lastCommand = commandToken;
    _lastCommandArgs = [x1, y1, x2, y2, x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.smoothCurveTo] and it's Argument [ValueToken]s.
  ///
  /// smooth-curve-to-args: x1,y1 x,y        (absolute)
  /// smooth-curve-to-args: dx1,dy1 dx,dy    (relative)
  _parseSmoothCurveTo(CommandToken commandToken) {
    var x2 = (_scanner.scan()! as ValueToken).value;
    var y2 = (_scanner.scan()! as ValueToken).value;
    var x = (_scanner.scan()! as ValueToken).value;
    var y = (_scanner.scan()! as ValueToken).value;
    // Calculate the first control point
    var cp = _calculateCubicControlPoint();

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this
          .path
          .cubicTo(cp.dx, cp.dy, x2 as double, y2 as double, x as double, y as double);
      _currentPoint = Offset(x, y);
    } else {
      this.path.cubicTo(cp.dx - _currentPoint.dx, cp.dy - _currentPoint.dy,
          x2 as double, y2 as double, x as double, y as double);
      _currentPoint.translate(x, y);
    }

    _lastCommand = commandToken;
    _lastCommandArgs = [x2, y2, x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.quadraticBezierCurveTo] and it's Argument [ValueToken]s.
  /// Parses a [CommandToken] of type [TokenType.smoothCurveTo] and it's Argument [ValueToken]s.
  ///
  /// quadratic-curve-to-args: x1,y1 x,y        (absolute)
  /// quadratic-curve-to-args: dx1,dy1 dx,dy    (relative)
  _parseQuadraticBezierCurveTo(CommandToken commandToken) {
    var x1 = (_scanner.scan()! as ValueToken).value;
    var y1 = (_scanner.scan()! as ValueToken).value;
    var x = (_scanner.scan()! as ValueToken).value;
    var y = (_scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.quadraticBezierTo(x1 as double, y1 as double, x as double, y as double);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeQuadraticBezierTo(
          x1 as double, y1 as double, x as double, y as double);
      _currentPoint.translate(x, y);
    }

    _lastCommand = commandToken;
    _lastCommandArgs = [x1, y1, x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.smoothQuadraticBezierCurveTo] and it's Argument [ValueToken]s.
  ///
  /// smooth-quadratic-curve-to-args: x,y         (absolute)
  /// smooth-quadratic-curve-to-args: dx,dy       (relative)
  _parseSmoothQuadraticBezierCurveTo(CommandToken commandToken) {
    var x = (_scanner.scan()! as ValueToken).value;
    var y = (_scanner.scan()! as ValueToken).value;
    // Calculate the control point
    var cp = _calculateQuadraticControlPoint();

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.quadraticBezierTo(cp.dx, cp.dy, x as double, y as double);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeQuadraticBezierTo(
          cp.dx - _currentPoint.dx, cp.dy - _currentPoint.dy, x as double, y as double);
      _currentPoint.translate(x, y);
    }

    _lastCommand = commandToken;
    _lastCommandArgs = [cp.dx, cp.dy, x, y];
  }

  /// Parses a [CommandToken] of type [TokenType.ellipticalArcTo] and it's Argument [ValueToken]s.
  ///
  /// smooth-curve-to-args: rx ry x-axis-rotation large-arc-flag sweep-flag x y     (absolute)
  /// smooth-curve-to-args: rx ry x-axis-rotation large-arc-flag sweep-flag dx dy   (relative)
  _parseEllipticalArcTo(CommandToken commandToken) {
    var rx = (_scanner.scan()! as ValueToken).value;
    var ry = (_scanner.scan()! as ValueToken).value;
    var theta = (_scanner.scan()! as ValueToken).value;
    var fa = (_scanner.scan()! as ValueToken).value == 1;
    var fb = (_scanner.scan()! as ValueToken).value == 1;
    var x = (_scanner.scan()! as ValueToken).value;
    var y = (_scanner.scan()! as ValueToken).value;

    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.arcToPoint(Offset(x as double, y as double),
          radius: Radius.elliptical(rx as double, ry as double),
          rotation: theta as double,
          largeArc: fa,
          clockwise: fb);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeArcToPoint(Offset(x as double, y as double),
          radius: Radius.elliptical(rx as double, ry as double),
          rotation: theta as double,
          largeArc: fa,
          clockwise: fb);
      _currentPoint.translate(x, y);
    }

    _lastCommand = commandToken;
    _lastCommandArgs = [rx, ry, theta, fa, fb, x, y];
  }

  /// Predicts the Control Point [Offset] for a smooth cubic curve command.
  Offset _calculateCubicControlPoint() {
    if (_lastCommand.type == TokenType.curveTo) {
      if (_lastCommand.coordinateType == CoordinateType.absolute) {
        return _currentPoint +
            (_currentPoint - Offset(_lastCommandArgs[2], _lastCommandArgs[3]));
      } else {
        return _currentPoint - Offset(_lastCommandArgs[2], _lastCommandArgs[3]);
      }
    } else if (_lastCommand.type == TokenType.smoothCurveTo) {
      if (_lastCommand.coordinateType == CoordinateType.absolute) {
        return _currentPoint +
            (_currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]));
      } else {
        return _currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]);
      }
    } else {
      return _currentPoint;
    }
  }

  /// Predicts the Control Point [Offset] for a smooth quadratic bezier curve command.
  Offset _calculateQuadraticControlPoint() {
    if (_lastCommand.type == TokenType.quadraticBezierCurveTo) {
      if (_lastCommand.coordinateType == CoordinateType.absolute) {
        return _currentPoint +
            (_currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]));
      } else {
        return _currentPoint - Offset(_lastCommandArgs[1], _lastCommandArgs[0]);
      }
    } else if (_lastCommand.type == TokenType.smoothQuadraticBezierCurveTo) {
      if (_lastCommand.coordinateType == CoordinateType.absolute) {
        return _currentPoint +
            (_currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]));
      } else {
        return _currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]);
      }
    } else {
      return _currentPoint;
    }
  }
}

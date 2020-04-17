import 'dart:ui';
import 'package:svg_path_parser/src/scanner.dart';
import 'package:svg_path_parser/src/tokens.dart';

class Parser {
  Parser(source)
      : _scanner = Scanner(source),
        path = Path(),
        _initialPoint = Offset.zero,
        _currentPoint = Offset.zero,
        _lastCommandArgs = [];

  CommandToken _lastCommand;

  List<dynamic> _lastCommandArgs;

  Offset _initialPoint;
  Offset _currentPoint;

  Path path;

  final Scanner _scanner;

  Path parse() {
    // Scan streamStart Token
    _parseStreamStart();

    while (_scanner.peek().type != TokenType.streamEnd) {
      _parseCommand();
    }

    _parseStreamEnd();

    return this.path;
  }

  _parseStreamStart() {
    _scanner.scan();
  }

  _parseStreamEnd() {
    _scanner.scan();
  }

  _parseCommand() {
    var token = _scanner.peek();
    // If previous command is to be repeated
    if (!(token is CommandToken)) {
      // Subsequent pairs after first Move to are considered as implicit
      // Line to commands. https://www.w3.org/TR/SVG/paths.html#PathDataMovetoCommands
      if (_lastCommand.type == TokenType.moveTo) {
        token = CommandToken(TokenType.lineTo, _lastCommand.coordinateType);
      } else {
        token = _lastCommand;
      }
    } else {
      token = _scanner.scan();
    }

    switch (token.type) {
      case TokenType.moveTo:
        _parseMoveTo(token);
        return;
      case TokenType.closePath:
        _parseClosePath(token);
        return;
      case TokenType.lineTo:
        _parseLineTo(token);
        return;
      case TokenType.horizontalLineTo:
        _parseHorizontalLineTo(token);
        return;
      case TokenType.verticalLineTo:
        _parseVerticalLineTo(token);
        return;
      case TokenType.curveTo:
        _parseCurveTo(token);
        return;
      case TokenType.smoothCurveTo:
        _parseSmoothCurveTo(token);
        return;
      case TokenType.quadraticBezierCurveTo:
        _parseQuadraticBezierCurveTo(token);
        return;
      case TokenType.smoothQuadraticBezierCurveTo:
        _parseSmoothQuadraticBezierCurveTo(token);
        return;
      case TokenType.ellipticalArcTo:
        _parseEllipticalArcTo(token);
        return;
      default:
        return;
    }
  }

  _parseMoveTo(CommandToken commandToken) {
    var x = (_scanner.scan() as ValueToken).value;
    var y = (_scanner.scan() as ValueToken).value;
    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.moveTo(x, y);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeMoveTo(x, y);
      _currentPoint.translate(x, y);
    }
    _initialPoint = _currentPoint;
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _lastCommandArgs.addAll([x, y]);
  }

  _parseClosePath(CommandToken commandToken) {
    this.path.close();
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _currentPoint = _initialPoint;
  }

  _parseLineTo(CommandToken commandToken) {
    var x = (_scanner.scan() as ValueToken).value;
    var y = (_scanner.scan() as ValueToken).value;
    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.lineTo(x, y);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeLineTo(x, y);
      _currentPoint.translate(x, y);
    }
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _lastCommandArgs.addAll([x, y]);
  }

  _parseHorizontalLineTo(CommandToken commandToken) {
    var h = (_scanner.scan() as ValueToken).value;
    var y = _currentPoint.dy;
    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.lineTo(h, y);
      _currentPoint = Offset(h, y);
    } else {
      this.path.relativeLineTo(h, 0);
      _currentPoint.translate(h, 0);
    }
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _lastCommandArgs.addAll([h]);
  }

  _parseVerticalLineTo(CommandToken commandToken) {
    var v = (_scanner.scan() as ValueToken).value;
    var x = _currentPoint.dx;
    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.lineTo(x, v);
      _currentPoint = Offset(x, v);
    } else {
      this.path.relativeLineTo(0, v);
      _currentPoint.translate(0, v);
    }
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _lastCommandArgs.addAll([v]);
  }

  _parseCurveTo(CommandToken commandToken) {
    var x1 = (_scanner.scan() as ValueToken).value;
    var y1 = (_scanner.scan() as ValueToken).value;
    var x2 = (_scanner.scan() as ValueToken).value;
    var y2 = (_scanner.scan() as ValueToken).value;
    var x = (_scanner.scan() as ValueToken).value;
    var y = (_scanner.scan() as ValueToken).value;
    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.cubicTo(x1, y1, x2, y2, x, y);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeCubicTo(x1, y1, x2, y2, x, y);
      _currentPoint.translate(x, y);
    }
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _lastCommandArgs.addAll([x1, y1, x2, y2, x, y]);
  }

  _parseSmoothCurveTo(CommandToken commandToken) {
    var x2 = (_scanner.scan() as ValueToken).value;
    var y2 = (_scanner.scan() as ValueToken).value;
    var x = (_scanner.scan() as ValueToken).value;
    var y = (_scanner.scan() as ValueToken).value;
    // Calculate the first control point
    var cp = _calculateCubicControlPoint();
    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.cubicTo(cp.dx, cp.dy, x2, y2, x, y);
      _currentPoint = Offset(x, y);
    } else {
      this.path.cubicTo(cp.dx - _currentPoint.dx, cp.dy - _currentPoint.dy, x2, y2, x, y);
      _currentPoint.translate(x, y);
    }
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _lastCommandArgs.addAll([x2, y2, x, y]);
  }

  _parseQuadraticBezierCurveTo(CommandToken commandToken) {
    var x1 = (_scanner.scan() as ValueToken).value;
    var y1 = (_scanner.scan() as ValueToken).value;
    var x = (_scanner.scan() as ValueToken).value;
    var y = (_scanner.scan() as ValueToken).value;
    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.quadraticBezierTo(x1, y1, x, y);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeQuadraticBezierTo(x1, y1, x, y);
      _currentPoint.translate(x, y);
    }
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _lastCommandArgs.addAll([x1, y1, x, y]);
  }

  _parseSmoothQuadraticBezierCurveTo(CommandToken commandToken) {
    var x = (_scanner.scan() as ValueToken).value;
    var y = (_scanner.scan() as ValueToken).value;
    // Calculate the control point
    var cp = _calculateQuadraticControlPoint();
    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.quadraticBezierTo(cp.dx, cp.dy, x, y);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeQuadraticBezierTo(cp.dx - _currentPoint.dx, cp.dy - _currentPoint.dy, x, y);
      _currentPoint.translate(x, y);
    }
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _lastCommandArgs.addAll([cp.dx, cp.dy, x, y]);
  }

  _parseEllipticalArcTo(CommandToken commandToken) {
    var rx = (_scanner.scan() as ValueToken).value;
    var ry = (_scanner.scan() as ValueToken).value;
    var theta = (_scanner.scan() as ValueToken).value;
    var fa = (_scanner.scan() as ValueToken).value == 1;
    var fb = (_scanner.scan() as ValueToken).value == 1;
    var x = (_scanner.scan() as ValueToken).value;
    var y = (_scanner.scan() as ValueToken).value;
    if (commandToken.coordinateType == CoordinateType.absolute) {
      this.path.arcToPoint(Offset(x, y),
          radius: Radius.elliptical(rx, ry), rotation: theta, largeArc: fa, clockwise: fb);
      _currentPoint = Offset(x, y);
    } else {
      this.path.relativeArcToPoint(Offset(x, y),
          radius: Radius.elliptical(rx, ry), rotation: theta, largeArc: fa, clockwise: fb);
      _currentPoint.translate(x, y);
    }
    _lastCommand = commandToken;
    _lastCommandArgs.clear();
    _lastCommandArgs.addAll([rx, ry, theta, fa, fb, x, y]);
  }

  Offset _calculateCubicControlPoint() {
    if (_lastCommand.type == TokenType.curveTo) {
      if (_lastCommand.coordinateType == CoordinateType.absolute) {
        return _currentPoint + (_currentPoint - Offset(_lastCommandArgs[2], _lastCommandArgs[3]));
      } else {
        return _currentPoint - Offset(_lastCommandArgs[2], _lastCommandArgs[3]);
      }
    } else if (_lastCommand.type == TokenType.smoothCurveTo) {
      if (_lastCommand.coordinateType == CoordinateType.absolute) {
        return _currentPoint + (_currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]));
      } else {
        return _currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]);
      }
    } else {
      return _currentPoint;
    }
  }

  Offset _calculateQuadraticControlPoint() {
    if (_lastCommand.type == TokenType.quadraticBezierCurveTo) {
      if (_lastCommand.coordinateType == CoordinateType.absolute) {
        return _currentPoint + (_currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]));
      } else {
        return _currentPoint - Offset(_lastCommandArgs[1], _lastCommandArgs[0]);
      }
    } else if (_lastCommand.type == TokenType.smoothQuadraticBezierCurveTo) {
      if (_lastCommand.coordinateType == CoordinateType.absolute) {
        return _currentPoint + (_currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]));
      } else {
        return _currentPoint - Offset(_lastCommandArgs[0], _lastCommandArgs[1]);
      }
    } else {
      return _currentPoint;
    }
  }
}

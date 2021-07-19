/// A token emitted by a [Scanner].
class Token {
  final TokenType type;

  Token(this.type);

  @override
  String toString() {
    return 'Token $type';
  }

  @override
  bool operator ==(other) {
    return (other is Token) && this.type == other.type;
  }

  @override
  int get hashCode => type.hashCode;
}

/// A Token representing a command.
class CommandToken implements Token {
  @override
  final TokenType type;

  /// Type of coordinates to use for the command.
  CoordinateType coordinateType;

  CommandToken(this.type, [this.coordinateType = CoordinateType.absolute]);

  @override
  String toString() {
    return 'COMMAND $type ($coordinateType)';
  }

  @override
  bool operator ==(other) {
    if (other is CommandToken) {
      return this.type == other.type &&
          this.coordinateType == other.coordinateType;
    }
    return false;
  }

  @override
  int get hashCode => type.hashCode * coordinateType.hashCode;
}

/// A token representing an argument value.
class ValueToken implements Token {
  @override
  final TokenType type;

  /// The value of the argument
  final Object? value;

  ValueToken(this.type, this.value);

  @override
  String toString() {
    return 'VALUE $type $value';
  }

  @override
  bool operator ==(other) {
    if (other is ValueToken) {
      return this.type == other.type && this.value == other.value;
    }
    return false;
  }

  @override
  int get hashCode => type.hashCode * value.hashCode;
}

/// The types of [Token] objects.
enum TokenType {
  // Move To / Draw To Commands
  moveTo,
  closePath,
  lineTo,
  horizontalLineTo,
  verticalLineTo,
  curveTo,
  smoothCurveTo,
  quadraticBezierCurveTo,
  smoothQuadraticBezierCurveTo,
  ellipticalArcTo,

  // Command Parameters
  value,
  flag,

  // Stream Start/End
  streamStart,
  streamEnd
}

/// The types of coordinates to use for commands.
enum CoordinateType { absolute, relative }

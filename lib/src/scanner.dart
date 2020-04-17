import 'dart:collection';

import 'package:string_scanner/string_scanner.dart';
import 'package:svg_path_parser/src/tokens.dart';

/// A scanner that reads a string of Unicode characters and emits [Token]s.
///
/// This scanner is based on the guidelines provided by W3C on svg path,
/// available at https://www.w3.org/TR/SVG11/paths.html.
class Scanner {
  static const LETTER_A = 0x41;
  static const LETTER_a = 0x61;
  static const LETTER_C = 0x43;
  static const LETTER_c = 0x63;
  static const LETTER_E = 0x45;
  static const LETTER_e = 0x65;
  static const LETTER_h = 0x48;
  static const LETTER_H = 0x68;
  static const LETTER_L = 0x4c;
  static const LETTER_l = 0x6c;
  static const LETTER_M = 0x4d;
  static const LETTER_m = 0x6d;
  static const LETTER_Q = 0x51;
  static const LETTER_q = 0x71;
  static const LETTER_S = 0x53;
  static const LETTER_s = 0x73;
  static const LETTER_T = 0x54;
  static const LETTER_t = 0x74;
  static const LETTER_V = 0x56;
  static const LETTER_v = 0x76;
  static const LETTER_Z = 0x5a;
  static const LETTER_z = 0x7a;

  static const NUMBER_0 = 0x30;
  static const NUMBER_9 = 0x39;

  static const MINUS_SIGN = 0x2d;
  static const PLUS_SIGN = 0x2b;
  static const PERIOD = 0x2e;
  static const COMMA = 0x2c;
  static const SP = 0x20;

  /// The [RegExp] pattern to match a valid float value. Allowed float values include
  /// starting with decimal (.3) and exponent notation (1.3e+4).
  static final floatPattern = RegExp(r'[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?');

  /// The [RegExp] pattern to match a valid non-negative float value. Allowed float
  /// values include starting with decimal (.3) and exponent notation (1.3e+4).
  static final nonNegativeFloatPattern = RegExp(r'[+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?');

  /// The [RegExp] pattern to match a boolean flag (`1` or `0`).
  static final flagPattern = RegExp(r'(0|1)(?=[,\s])');

  /// Queue of tokens generated to be returned.
  final _tokens = Queue<Token>();

  /// The underlying StringScanner which scans the [source].
  final StringScanner _scanner;

  /// Is the stream end token is produced.
  bool _streamEndProduced = false;

  /// Is the stream start token is produced.
  bool _streamStartProduced = false;

  /// checks if the next character is a whitespace character.
  bool get _isWhitespace => _isWhitespaceAt(0);

  /// checks if the next character is a command character.
  bool get _isCommand => _isCommandAt(0);

  /// checks if the next character is a comma.
  bool get _isSeparator => _scanner.peekChar() == COMMA;

  /// checks if the end of string is reached.
  bool get isDone => _scanner.isDone;

  /// returns the [CoordinateType] based on the case of a character
  CoordinateType _coordinateType(char) {
    return _isLowerChar(char) ? CoordinateType.relative : CoordinateType.absolute;
  }

  bool _isWhitespaceAt(int offset) {
    var char = _scanner.peekChar(offset);
    return char == 0x20 || char == 0x9 || char == 0xd || char == 0xa;
  }

  bool _isCommandAt(int offset) {
    var char = _scanner.peekChar();
    return [
      LETTER_A,
      LETTER_a,
      LETTER_C,
      LETTER_c,
      LETTER_H,
      LETTER_h,
      LETTER_L,
      LETTER_l,
      LETTER_M,
      LETTER_m,
      LETTER_Q,
      LETTER_q,
      LETTER_S,
      LETTER_s,
      LETTER_T,
      LETTER_t,
      LETTER_V,
      LETTER_v,
      LETTER_Z,
      LETTER_z,
    ].contains(char);
  }

  bool _isLowerChar(char) {
    return (LETTER_a <= char && char <= LETTER_z);
  }

  /// Creates a [Scanner] that scans [source].
  ///
  /// [source] cannot be `null`.
  Scanner(String source) : _scanner = StringScanner(source) {
    if (source == null) throw ArgumentError.notNull('source');
  }

  /// Consumes and returns the next token.
  Token scan() {
    if (_streamEndProduced) return null;
    if (_tokens.isEmpty) _fetchNextToken();
    return _tokens.removeFirst();
  }

  /// Returns the next token without consuming it.
  Token peek() {
    if (_streamEndProduced) return null;
    if (_tokens.isEmpty) _fetchNextToken();
    return _tokens.first;
  }

  /// Populates [_tokens] by fetching more tokens.
  _fetchNextToken() {
    if (!_streamStartProduced) {
      _fetchStreamStart();
      return;
    }

    _scanToNextToken();

    if (_scanner.isDone) {
      _fetchStreamEnd();
      return;
    }

    if (_isCommand) {
      _fetchCommand();
      return;
    }

    _invalidCharacter(1);
  }

  /// Fetches a [CommandToken] and the required arguments' [ValueToken]s.
  _fetchCommand() {
    var coordinateType = _coordinateType(_scanner.peekChar());
    var tokenType = _scanCommand();

    _tokens.add(CommandToken(tokenType, coordinateType));

    switch (tokenType) {
      case TokenType.ellipticalArcTo:
        _fetchArcCommandParams();
        return;
      case TokenType.curveTo:
        _fetchMultipleCoordinatePair(3);
        return;
      case TokenType.smoothCurveTo:
      case TokenType.quadraticBezierCurveTo:
        _fetchMultipleCoordinatePair(2);
        return;
      case TokenType.lineTo:
      case TokenType.moveTo:
      case TokenType.smoothQuadraticBezierCurveTo:
        _fetchCoordinatePair();
        return;
      case TokenType.horizontalLineTo:
      case TokenType.verticalLineTo:
        _fetchCoordinate();
        return;
      case TokenType.closePath:
        return;
    }
  }

  /// Consumes whitespaces and commas until the next token or
  /// the end of source is reached.
  _scanToNextToken() {
    while (!isDone && (_isWhitespace || _isSeparator)) {
      _scanner.readChar();
    }
  }

  /// Consumes all the whitespace till a non-whitespace character occurs
  /// or till the end of the source.
  _skipWhitespace() {
    while (!isDone && _isWhitespace) {
      _scanner.readChar();
    }
  }

  /// Fetches a stream start token.
  _fetchStreamStart() {
    _tokens.add(Token(TokenType.streamStart));
    _streamStartProduced = true;
  }

  /// Fetches a stream end token.
  _fetchStreamEnd() {
    _tokens.add(Token(TokenType.streamEnd));
    _streamEndProduced = true;
  }

  /// Fetches a comma but raises an error when a second comma is found.
  _fetchSeparator() {
    _skipWhitespace();
    if (_scanner.scanChar(COMMA)) {
      _skipWhitespace();
      // Extra comma would raise an error.
      if (_scanner.peekChar() == COMMA) {
        _invalidCharacter(1);
      }
    }
    _skipWhitespace();
  }

  /// Fetch the next comma.
  _fetchSingleSeparator() {
    _skipWhitespace();
    _scanner.scanChar(COMMA);
  }

  /// Fetch a float value.
  _fetchFloatValue() => _tokens.add(ValueToken(TokenType.value, _scanFloatValue()));

  /// Fetch a non-negative float value.
  _fetchNonNegativeFloatValue() {
    _tokens.add(ValueToken(TokenType.value, _scanNonNegativeFloatValue()));
  }

  /// Fetch a boolean (1 | 0) flag.
  _fetchFlag() => _tokens.add(ValueToken(TokenType.flag, _scanFlag()));

  /// Fetch Parameters for ellipticalArcTo command.
  ///
  /// Production for ellipticalArcTo Arguments:
  ///   elliptical-arc-argument-sequence: elliptical-arc-argument+
  ///   elliptical-arc-argument:
  ///     nonnegative-number comma-wsp? nonnegative-number comma-wsp?
  ///       number comma-wsp flag comma-wsp? flag comma-wsp? coordinate-pair
  _fetchArcCommandParams() {
    do {
      _skipWhitespace();
      _fetchNonNegativeFloatValue();
      _fetchSeparator();
      _fetchNonNegativeFloatValue();
      _fetchSeparator();
      _fetchFloatValue();
      _fetchSeparator();
      _fetchFlag();
      _fetchSeparator();
      _fetchFlag();
      _fetchSeparator();
      _fetchSingleCoordinatePair();
    } while (!isDone && !_isCommand);
  }

  /// Fetch coordinate Pairs for moveTo, LineTo, smoothQuadraticBezierCurveTo commands.
  ///
  /// Production for ellipticalArcTo Arguments:
  ///   lineto-argument-sequence:
  ///    coordinate-pair
  ///    | coordinate-pair comma-wsp? lineto-argument-sequence
  _fetchCoordinatePair() {
    do {
      _skipWhitespace();
      _fetchSingleCoordinate();
      _fetchSeparator();
      _fetchSingleCoordinate();
      _fetchSingleSeparator();
    } while (!isDone && !_isCommand && !_isSeparator);
  }

  /// Fetch Single coordinates for horizontalMoveTo, verticalMoveTo commands.
  ///
  /// Production for ellipticalArcTo Arguments:
  ///   horizontal-lineto-argument-sequence:
  ///    coordinate
  ///    | coordinate comma-wsp? horizontal-lineto-argument-sequence
  _fetchCoordinate() {
    do {
      _fetchSingleCoordinate();
      _fetchSingleSeparator();
    } while (!isDone && !_isCommand && !_isSeparator);
  }

  /// Fetch a single float value
  _fetchSingleCoordinate() {
    _fetchFloatValue();
    _skipWhitespace();
  }

  /// Fetch a single coordinate pair
  _fetchSingleCoordinatePair() {
    _skipWhitespace();
    _fetchSingleCoordinate();
    _fetchSeparator();
    _fetchSingleCoordinate();
  }

  /// fetches Multiple coordinate Pairs.
  ///
  /// Used to fetch Arguments for curveTo, smoothCurveTo, quadraticBezierCurveTo commands.
  _fetchMultipleCoordinatePair(int count) {
    do {
      for (var i = 1; i <= count; i++) {
        _skipWhitespace();
        _fetchSingleCoordinate();
        _fetchSeparator();
        _fetchSingleCoordinate();
        _fetchSingleSeparator();
      }
    } while (!isDone && !_isCommand && !_isSeparator);
  }

  /// scans the source and generates a [CommandToken].
  _scanCommand() {
    var char = _scanner.readChar();
    if (char == LETTER_A || char == LETTER_a) return TokenType.ellipticalArcTo;
    if (char == LETTER_C || char == LETTER_c) return TokenType.curveTo;
    if (char == LETTER_H || char == LETTER_h) return TokenType.horizontalLineTo;
    if (char == LETTER_L || char == LETTER_l) return TokenType.lineTo;
    if (char == LETTER_M || char == LETTER_m) return TokenType.moveTo;
    if (char == LETTER_Q || char == LETTER_q) return TokenType.quadraticBezierCurveTo;
    if (char == LETTER_S || char == LETTER_s) return TokenType.smoothCurveTo;
    if (char == LETTER_T || char == LETTER_t) return TokenType.smoothQuadraticBezierCurveTo;
    if (char == LETTER_V || char == LETTER_v) return TokenType.verticalLineTo;
    if (char == LETTER_Z || char == LETTER_z) return TokenType.closePath;
  }

  /// scans the source and generates a [ValueToken].
  double _scanFloatValue() {
    if (_scanner.matches(floatPattern)) {
      _scanner.scan(floatPattern);
      return double.parse(_scanner.lastMatch.group(0));
    } else {
      _expectedFloatValue();
    }
    return null;
  }

  /// scans the source and generates a [ValueToken].

  double _scanNonNegativeFloatValue() {
    if (_scanner.matches(nonNegativeFloatPattern)) {
      _scanner.scan(nonNegativeFloatPattern);
      return double.parse(_scanner.lastMatch.group(0));
    } else {
      _expectedNonNegativeFloatValue();
    }
    return null;
  }

  /// scans the source and generates a [ValueToken] having [TokenType.flag].
  _scanFlag() {
    if (_scanner.scan(flagPattern)) {
      return int.parse(_scanner.lastMatch.group(0));
    } else {
      _expectedZeroOneValue();
    }
  }

  /// Raise an error for a unexpected character.
  _invalidCharacter([int length = 0]) {
    _scanner.error('Unexpected character.', length: length);
  }

  /// Raise an error when a float value is not found
  _expectedFloatValue() {
    _scanner.error("Expected a float Value.");
  }

  /// Raise an error when a non-negative float value is not found
  _expectedNonNegativeFloatValue() {
    _scanner.error("Expected a non-negative float Value.");
  }

  /// Raise an error when a boolean(1 | 0) is not found.
  _expectedZeroOneValue() {
    _scanner.error("Expected a 0 or 1.");
  }
}

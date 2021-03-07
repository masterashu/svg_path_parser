library svg_path_parser;

import 'src/parser.dart';
import 'dart:ui';

export 'src/tokens.dart';
export 'src/scanner.dart';
export 'src/parser.dart';

/// A wrapper to quickly parse a Svg path.
Path parseSvgPath(String source, {bool failSilently = false}) {
  try {
    return Parser(source).parse();
  } catch (e) {
    if (!failSilently) {
      rethrow;
    } else {
      return Path();
    }
  }
}

import 'package:svg_path_parser/svg_path_parser.dart';

bool equalToken(Token a, Token b) {
  if (a is CommandToken && b is CommandToken) {
    return a.type == b.type && a.coordinateType == b.coordinateType;
  } else if (a is ValueToken && b is ValueToken) {
    return a.value == b.value;
  } else {
    return false;
  }
}

# svg_path_parser
[![Pub Version (including pre-releases)](https://img.shields.io/pub/v/svg_path_parser?include_prereleases)](https://pub.dev/packages/svg_path_parser)
[![Flutter Test package](https://github.com/masterashu/svg_path_parser/workflows/Flutter%20Test%20package/badge.svg)](https://github.com/masterashu/svg_path_parser/actions)

A Flutter/Dart utility to parse an SVG path into a equivalent Path object from `dart:ui` library.

## Getting Started

Add this to your package's **pubspec.yaml** file:

```yaml
dependencies:
  svg_path_parser: ^1.0.0
```

Now in your Dart code, you can use:

```dart
import 'package:svg_path_parser/svg_path_parser.dart';
```

You can use `parseSvgPath()` to parse a valid SVG path string to [Path](https://api.flutter.dev/flutter/dart-ui/Path-class.html) object;

```dart
Path path = parseSvgPath('m.29 47.85 14.58 14.57 62.2-62.2h-29.02z');
```

## Examples
View the [example](https://github.com/masterashu/svg_path_parser/tree/master/example) 
folder to see an example (drawing flutter logo using svg paths).


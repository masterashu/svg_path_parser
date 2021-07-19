## [1.1.0] - 19-July-2021

* Fixed an issue where using an absolute command after 
  a relative command will lead to wrong parsing behavior.  
  See details here: [issue#6](https://github.com/masterashu/svg_path_parser/issues/6)

## [1.0.0] - 7-March-2021

* Added null safety support
* Fixed unable to parse the sequence `H 4` and similar. [issue](https://github.com/masterashu/svg_path_parser/issues/3)
* Fix Typo in README

## [0.1.1] - 31-May-2020

* Added flag failSilently to [parseSvgPath](https://pub.dev/documentation/svg_path_parser/latest/svg_path_parser/parseSvgPath.html)
which will return an empty Path object if the provided path is invalid.

## [0.1.0] - 18-April-2020

Changes:
  * Added example
  * Added Testcase for Parser
  * Added Docs for Parser

## [0.0.9] - 17-April-2020

* Initial Development release.
  * Added Testcase

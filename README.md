# tsv2json

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)

Turn TSV file or stream into JSON file or stream.

Input file or stream should be UTF-8 if you want a (syntactically correct) JSON file using UTF-8.

The utility is written wholly in Nim and has no external dependencies.

Input file or stream is checked for the presence of double quotes, and turns them into single quotes, so as to not break JSON syntax.

When one TSV record is accidentally split over two or more lines (e.g., because of some field carrying CR/LF characters), tsv2json attempts a restoration of a good record by turning CR or LF characters into a space character.

A reasonably fast and small executable can be made by issuing this compiling command:

```
nim -f c -d:danger --app:console --opt:speed --passc:-flto tsv2json.nim && strip -s tsv2json && upx --best tsv2json
```

## Examples

Simple conversion using filename as parameter:

```
tsv2json file.tsv >file.json
```

Same, but using stdin stream:

```
tsv2json <file.tsv >file.json
```

Just read help:

```
tsv2json -h
```

Just know the version:

```
tsv2json -v
```

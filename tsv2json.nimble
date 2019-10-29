# Package

version       = "0.1.5"
author        = "Héctor M. Monacci"
description   = "Turn TSV file or stream into JSON file or stream"
license       = "MIT"
srcDir        = "src"
bin           = @["tsv2json"]
skipExt       = @["nim"] 


# Dependencies

requires "nim >= 1.0.2"

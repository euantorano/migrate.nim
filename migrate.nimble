# Package

version       = "1.0.0"
author        = "Euan T"
description   = "A database migration tool written in Nim."
license       = "BSD3"

bin = @["migrate"]

# Dependencies

requires "nim >= 0.14.0", "docopt >= 0.6.2"

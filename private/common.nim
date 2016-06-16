## Common types shared both publicly and privately.

from sets import HashSet, initSet, incl
from os import walkDir, extractFilename, pcFile
from strutils import endsWith
from uri import Uri

type
  MigrationResult* = tuple[numRan: int, batchNumber: int]
    ## The result of running a migration - how many changes were applied, and the batch number applied to the migration.
  RanMigration* = tuple[filename: string, batch: int]
    ## A migration that has been ran.
  ConnectionType* {.pure.} = enum
    ## The type of the database connection
    mysql = "mysql"
    postgres = "pgsql"
    sqlite = "sqlite3"
    unknown
  ConnectionSettingsObj = object
    ## Settings for a database connection
    connectionType*: ConnectionType
    server*: string
    username*: string
    password*: string
    db*: string
  ConnectionSettings* = ref ConnectionSettingsObj
    ## Settings for a database connection

proc getConnectionTypeFromScheme(scheme: string): ConnectionType =
  ## Get the connection type from a conenction string scheme
  case scheme
  of $ConnectionType.mysql:
    return ConnectionType.mysql
  of $ConnectionType.postgres:
    return ConnectionType.postgres
  of $ConnectionType.sqlite:
    return ConnectionType.sqlite
  else:
    return ConnectionType.unknown

proc getConnectionSettings*(url: Uri): ConnectionSettings =
  ## Get the conneciton settings from the given URL.
  new result
  result.connectionType = getConnectionTypeFromScheme(url.scheme)
  result.server = url.hostname
  result.username = url.username
  result.password = url.password
  result.db = url.path

  if result.db[0] == '/':
    result.db = result.db[1..len(result.db)]

proc getFilenamesToCheck*(path, postfix: string): HashSet[string] =
  ## Get a set of file names to check from the given directory with the given postfix.
  result = initSet[string]()
  for kind, path in walkDir(path):
    if kind == pcFile and path.endsWith(postfix):
      result.incl(extractFilename(path))

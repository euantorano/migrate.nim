## Driver concept and implementation.

import uri, db_common, sets, os, strutils

import common
export common

type
  ConnectionSettings* = tuple[server: string, username: string, password: string, db: string]
  Driver* = ref object of RootObj
    connectionSettings*: ConnectionSettings
    migrationPath*: string

proc getConnectionSettings*(url: Uri): ConnectionSettings =
  ## Get the conneciton settings from the given URL.
  result.server = url.hostname
  result.username = url.username
  result.password = url.password
  result.db = url.path

  if result.db[0] == '/':
    result.db = result.db[1..len(result.db)]

proc getFilenamesToCheck*(path, postfix: string): HashSet[string] =
  result = initSet[string]()
  for kind, path in walkDir(path):
    if kind == pcFile and path.endsWith(postfix):
      result.incl(extractFilename(path))

method ensureMigrationsTableExists*(d: Driver) {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard

method closeDriver*(d: Driver) {.tags: [DbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard

method runUpMigration(d: Driver, query: string) {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard

method runDownMigration(d: Driver, query: string) {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard

method getUpMigrationsToRun(d: Driver, path: string): seq[string] {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard

method getDownMigrationsToRun(d: Driver, path: string): seq[string] {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard

method getLastBatchNumber(d: Driver): int {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard

method getNextBatchNumber(d: Driver): int {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard

method runUpMigrations*(d: Driver, path: string): MigrationResult {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect, RootEffect], base.} = discard

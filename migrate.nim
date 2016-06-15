## A database migration tool written in Nim.

import private/common, private/driver
export common
from private/driver_mysql import initMysqlDriver

from os import expandFilename, existsDir, createDir, joinPath, changeFileExt
from uri import parseUri, Uri
from times import epochTime

type
  MigrationDirection {.pure.} = enum
    up = ".up", down = ".down"
  Migration* = tuple[up: string, down: string]
    ## A migration is made up of two files - one which apply the DB change, and another to revert it.
  MigratorObj = object
    basePath: string
    driver: Driver
  Migrator* = ref MigratorObj
    ## A migrator is used to run migrations.

proc getDriver(connectionSettings: ConnectionSettings, migrationPath: string): Driver =
  ## Get the database driver for the given connection settings.
  case connectionSettings.connectionType
  of ConnectionType.mysql:
    result = initMysqlDriver(connectionSettings, migrationPath)
  of ConnectionType.postgres:
    echo "Using Postgresql"
    result = nil
  of ConnectionType.sqlite:
    echo "Using sqlite"
    result = nil
  of ConnectionType.unknown:
    result = nil

proc getDriver(connectionString, migrationPath: string): Driver =
  ## Get the database driver for the given connection string.
  let url = parseUri(connectionString)
  let connectionSettings = getConnectionSettings(url)

  result = getDriver(connectionSettings, migrationPath)

proc initMigrator*(migrationsPath = "./", connectionString: string = ""): Migrator =
  ## Initialize a new migrator, with the given migration path and connection string.
  new result
  result.basePath = expandFilename(migrationsPath)

  if not existsDir(result.basePath):
    createDir(result.basePath)

  result.driver = getDriver(connectionString, result.basePath)

proc initMigrator*(migrationsPath = "./", connectionSettings: ConnectionSettings): Migrator =
  ## Initialize a new migrator, with the given migration path and connection string.
  new result
  result.basePath = expandFilename(migrationsPath)

  if not existsDir(result.basePath):
    createDir(result.basePath)

  result.driver = getDriver(connectionSettings, result.basePath)

proc getPathForMigration(m: Migrator, name: string, direction: MigrationDirection): string =
  ## Get the path to a migration file in the given directory with the given direction.
  result = joinPath(m.basePath, name)
  result = changeFileExt(result, $direction & ".sql")

proc createMigration*(m: Migrator, name: string): Migration =
  ## Create a new migration with the given name. The full path to the created
  result = (up: "", down: "")

  let currentEpochTime = epochTime().int
  let fileName = $currentEpochTime & "_" & name
  result.up = m.getPathForMigration(fileName, MigrationDirection.up)
  result.down = m.getPathForMigration(fileName, MigrationDirection.down)

  let upFile = open(result.up, mode = fmReadWrite)
  defer: close(upFile)

  let downFile = open(result.down, mode = fmReadWrite)
  defer: close(downFile)

proc up*(m: Migrator): MigrationResult =
  ## Apply all pending database changes.
  if m.driver != nil:
    m.driver.ensureMigrationsTableExists()
    result = m.driver.runUpMigrations(m.basePath)

when isMainModule:
  import docopt, logging, uri, os, strutils, private/driver_mysql

  const
    doc = """
Migrate.

Usage:
  migrate new <name> [--path=<migrations_dir>]
  migrate (up|down) <connection_string> [--path=<migrations_dir>]
  migrate (-h | --help)
  migrate --version

Options:
  -h --help     Show this screen.
  --version     Show version.
"""
    version = "1.0.0"

  proc migrateDown(connectionString, path: string) =
    let driver = getDriver(connectionString, path)

    if driver != nil:
      defer: driver.closeDriver()
      driver.ensureMigrationsTableExists()

  proc resolvePath(path: Value): string =
    if path.kind == vkNone:
      result = getCurrentDir()
    else:
      result = $path

  proc main() =
    let args = docopt(doc, version = version)

    var consoleLogger = newConsoleLogger()
    addHandler(consoleLogger)

    let path = resolvePath(args["--path"])

    let migrator = initMigrator(path, $args["<connection_string>"])

    if args["new"]:
      let created = migrator.createMigration($args["<name>"])
      info("Ceated migration files: ", created.up, " and ", created.down)
    elif args["up"]:
      let migrationResults = migrator.up()
      info("Ran ", $migrationResults.numRan, " migrations, with batch number: ", $migrationResults.batchNumber)
    elif args["down"]:
      migrateDown($args["<connection_string>"], path)

  main()

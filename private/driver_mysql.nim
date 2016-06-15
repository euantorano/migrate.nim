## MySQL migration driver.

import driver

import db_mysql, uri, strutils, logging, sets, algorithm, os


const
  createMigrationsTableCommand = sql"""CREATE TABLE IF NOT EXISTS migrations(
    filename VARCHAR(255) NOT NULL,
    batch INT unsigned
  );"""
  getRanMigrationsCommand = sql"SELECT filename FROM migrations ORDER BY batch ASC, filename ASC;"
  getNextBatchNumberCommand = sql"SELECT MAX(batch) FROM migrations;"
  insertRanMigrationCommand = sql"INSERT INTO migrations(filename, batch) VALUES (?, ?);"

type
  MysqlDriver* = ref object of Driver
    handle: DbConn

proc initMysqlDriver*(settings: ConnectionSettings, migrationPath: string): MysqlDriver =
  new result
  result.connectionSettings = settings
  result.migrationPath = migrationPath
  result.handle = open(settings.server, settings.username,
                       settings.password, settings.db)

method ensureMigrationsTableExists*(d: MysqlDriver) =
  d.handle.exec(createMigrationsTableCommand)

method closeDriver*(d: MysqlDriver) =
  debug("Closing MySQL connection")
  d.handle.close()

proc runUpMigration(d: MysqlDriver, query, migration: string, batch: int): bool =
  result = false
  try:
    d.handle.exec(SqlQuery(query))
    d.handle.exec(insertRanMigrationCommand, migration, batch)
    result = true
  except DbError:
    error("Error running migration '", migration, "': ", getCurrentExceptionMsg())

proc runDownMigration(d: MysqlDriver, query: string) = discard

proc getLastBatchNumber(d: MysqlDriver): int =
  result = 0
  let value = d.handle.getValue(getNextBatchNumberCommand)
  if value == nil or value == "":
    result = 0
  else:
    result = parseInt(value)

proc getNextBatchNumber(d: MysqlDriver): int =
  let lastNumber = d.getLastBatchNumber()
  echo $lastNumber
  result = lastNumber + 1

iterator getRanMigrations(d: MysqlDriver): string =
  ## Get a list of all of the migrations that have already been ran.
  for row in d.handle.rows(getRanMigrationsCommand):
    yield row[0]

proc getUpMigrationsToRun(d: MysqlDriver, path: string): HashSet[string] =
  debug("Calculating up migrations to run against MySQL")
  result = getFilenamesToCheck(path, ".up.sql")
  var ranMigrations = initSet[string]()

  for migration in d.getRanMigrations():
    ranMigrations.incl(migration)

  debug("Found ", len(ranMigrations), " already ran migrations")

  result.excl(ranMigrations)

  debug("Got ", len(result), " files to run: ", $result)

method runUpMigrations*(d: MysqlDriver, path: string): MigrationResult =
  result = (numRan: 0, batchNumber: d.getnextBatchNumber())

  var fileContent: TaintedString
  for file in d.getUpMigrationsToRun(path):
    debug("Running migration: ", file)
    fileContent = readFile(d.migrationPath / file)
    if fileContent != nil and len(fileContent) > 0:
      if d.runUpMigration(fileContent, file, result.batchNumber):
        result.numRan = result.numRan + 1

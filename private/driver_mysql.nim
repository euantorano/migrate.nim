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
  removeRanMigrationCommand = sql"DELETE FROM migrations WHERE filename = ? AND batch = ?;"
  getRanMigrationsForBatchCommand = sql"SELECT filename FROM migrations WHERE batch = ? ORDER BY filename ASC;"

type
  MysqlDriver* = ref object of Driver
    handle: DbConn

proc initMysqlDriver*(settings: ConnectionSettings, migrationPath: string): MysqlDriver =
  new result
  result.connectionSettings = settings
  result.migrationPath = migrationPath
  result.handle = open(settings.server, settings.username, settings.password, settings.db)

method ensureMigrationsTableExists*(d: MysqlDriver) =
  ## Make sure that the `migrations` table exists in the database.
  d.handle.exec(createMigrationsTableCommand)

method closeDriver*(d: MysqlDriver) =
  ## Close the driver and the underlying database connection.
  debug("Closing MySQL connection")
  d.handle.close()

proc runUpMigration(d: MysqlDriver, query, migration: string, batch: int): bool =
  ## Run and record an upwards migration.
  result = false
  try:
    d.handle.exec(SqlQuery(query))
    d.handle.exec(insertRanMigrationCommand, migration, batch)
    result = true
  except DbError:
    error("Error running migration '", migration, "': ", getCurrentExceptionMsg())

proc runDownMigration(d: MysqlDriver, query, migration: string, batch: int): bool =
  ## Run and remove a downwards migration.
  result = false
  try:
    d.handle.exec(SqlQuery(query))
    d.handle.exec(removeRanMigrationCommand, migration, batch)
    result = true
  except DbError:
    error("Error reversing migration '", migration, "': ", getCurrentExceptionMsg())

proc getLastBatchNumber(d: MysqlDriver): int =
  ## Get the last used batch number from the `migrations` table.
  result = 0
  let value = d.handle.getValue(getNextBatchNumberCommand)
  if value == nil or value == "":
    result = 0
  else:
    result = parseInt(value)

proc getNextBatchNumber(d: MysqlDriver): int =
  ## Get the next batch number.
  let lastNumber = d.getLastBatchNumber()
  result = lastNumber + 1

iterator getRanMigrations(d: MysqlDriver): string =
  ## Get a list of all of the migrations that have already been ran.
  for row in d.handle.rows(getRanMigrationsCommand):
    yield row[0]

proc getUpMigrationsToRun(d: MysqlDriver, path: string): HashSet[string] =
  ## Get a set of pending upwards migrations from the given path.
  debug("Calculating up migrations to run")
  result = getFilenamesToCheck(path, ".up.sql")
  var ranMigrations = initSet[string]()

  for migration in d.getRanMigrations():
    ranMigrations.incl(migration)

  debug("Found ", len(ranMigrations), " already ran migrations")

  result.excl(ranMigrations)

  debug("Got ", len(result), " files to run: ", $result)

method runUpMigrations*(d: MysqlDriver): MigrationResult =
  ## Run all of the outstanding upwards migrations.
  result = (numRan: 0, batchNumber: d.getnextBatchNumber())

  var fileContent: TaintedString
  for file in d.getUpMigrationsToRun(d.migrationPath):
    debug("Running migration: ", file)
    fileContent = readFile(d.migrationPath / file)
    if fileContent != nil and len(fileContent) > 0:
      if d.runUpMigration(fileContent, file, result.batchNumber):
        inc result.numRan

iterator getMigrationsForBatch(d: MysqlDriver, batch: int): string =
  ## Get all of the migrations that have been ran for a given batch.
  for row in d.handle.rows(getRanMigrationsForBatchCommand, batch):
    yield row[0]

method revertLastRanMigrations*(d: MysqlDriver): MigrationResult =
  ## Wind back the most recent batch of migrations.
  result = (numRan: 0, batchNumber: d.getLastBatchNumber())

  debug("Calculating down migrations to run for batch number ", result.batchNumber)

  var downFileName: string
  var downFilePath: string
  var fileContent: TaintedString
  for file in d.getMigrationsForBatch(result.batchNumber):
    if file.endsWith(".up.sql"):
      debug("Found migration to revert: ", file)
      downFileName = file[0..^8] & ".down.sql"
      downFilePath = d.migrationPath / downFileName
      if existsFile(downFilePath):
        debug("Running down migration: ", downFilePath)
        fileContent = readFile(downFilePath)
        if d.runDownMigration(fileContent, file, result.batchNumber):
          inc result.numRan

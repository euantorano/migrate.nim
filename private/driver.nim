## Driver concept and implementation.

from db_common import DbError, DbEffect, WriteDbEffect, ReadDbEffect

import common
export common

type
  Driver* = ref object of RootObj
    connectionSettings*: ConnectionSettings
    migrationPath*: string

method ensureMigrationsTableExists*(d: Driver) {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard
  ## Make sure that the `migrations` table exists in the database.

method closeDriver*(d: Driver) {.tags: [DbEffect, TimeEffect, WriteIOEffect, ReadIOEffect], base.} = discard
  ## Close the driver and the underlying database connection.

method runUpMigrations*(d: Driver): MigrationResult {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect, RootEffect], base.} = discard
  ## Run all of the outstanding upwards migrations.

method revertLastRanMigrations*(d: Driver): MigrationResult {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect, RootEffect], base.} = discard
  ## Wind back the most recent batch of migrations.

method revertAllMigrations*(d: Driver): MigrationResult {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect, RootEffect], base.} = discard
  ## Wind back all of the ran migrations.

method getAllTablesForDatabase*(d: Driver, database: string): (iterator: string) {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect, RootEffect], base.} = discard
  ## Get the names of all of the tables within the given database.

method getCreateForTable*(d: Driver, table: string): string {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect, RootEffect], base.} = discard
  ## Get the create syntax for the given table.

method getDropForTable*(d: Driver, table: string): string {.raises: [Exception, DbError], tags: [WriteDbEffect, ReadDbEffect, TimeEffect, WriteIOEffect, ReadIOEffect, RootEffect], base.} = discard
  ## Get the drop syntax for the given table.

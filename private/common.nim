## Common types shared both publicly and privately.

type
  MigrationResult* = tuple[numRan: int, batchNumber: int]
    ## The result of running a migration - how many changes were applied, and the batch number applied to the migration.

# migrate.nim

A simple database migration utility for Nim.

Database migrations let you easily manage the state of your SQL database, tracking and automating the applying of changes.

This package is available as both a library and a command line application, with very similar interfaces.

This package currently only supports MySQL and is fairly opinionated about how things should work, with migrations consisting of two files, both of which are prefixed with the current timestamp. These files (`xxx.up.sql` and `xxx.down.sql`) describe the process to run a migration, and to then later revert that migration.

Unfortunately, this package currently only supports MySQL, but patches for other database engines are very welcome!

## Installation

### CLI Application

The command line application can be installed either by downloading one of the prebuilt releases, or by compiling it yourself. Compilation requires [Nim](http://nim-lang.org) and [Nimble](https://github.com/nim-lang/nimble), as well as the required support DLLS for MySQL.

```
git clone https://github.com/euantorano/migrate.nim.git
cd migrate.nim
nimble build
```

This will build a single executable, `migrate` which can then be placed in your `PATH`.

### Package

The package can be installed via Nimble, by simply requiring it in your project's `.nimble` file:

```
# Dependencies

requires "migrate >= 1.0.0"
```

It can also be installed by running `nimble install migrate`.

## Usage

### CLI Application

The first step to using the command line application is to create a new migration:

```
$ ./migrate new create_a_table --path=./migrations
INFO Created migration files: /home/euan/migrate.nim/migrations/1466067778_create_a_table.up.sql and /home/euan/migrate.nim/migrations/1466067778_create_a_table.down.sql
```

You can then edit the two newly created files with the required code to apply and revert your migration. Once done, you can apply your migration:

```
$ ./migrate.exe up mysql://root@localhost/test --path=./migrations
DEBUG Calculating up migrations to run
DEBUG Found 0 already ran migrations
DEBUG Got 1 files to run: {1466067778_create_a_table.up.sql}
DEBUG Running migration: 1466067778_create_a_table.up.sql
INFO Ran 1 migrations, with batch number: 1
```

Note the string `mysql://root@localhost/test` - this is the connection string for your database that you wish to apply your migrations to. It takes the form of `<protocol>://<username>[:<password>]@<server>[:<port>]/<database>`.

To later revert a migration, you can simply run the `down` command:

```
$ ./migrate.exe down mysql://root@localhost/test --path=./migrations
DEBUG Calculating down migrations to run for batch number 1
DEBUG Found migration to revert: 1466067778_create_a_table.up.sql
DEBUG Running down migration: /home/euan/migrate.nim/migrations/1466067778_create_a_table.down.sql
INFO Reverted 1 migrations, with batch number: 1
```

If you want to completely revert all ran migrations, you can do so using the `clean` command:

```
$ ./migrate.exe clean mysql://root@localhost/test --path=./migrations
DEBUG Calculating down migrations to run
DEBUG Found migration to revert: 1466065177_create_euan_test_table.up.sql
DEBUG Running down migration: /home/euan/migrate.nim/migrations/1466065177_create_euan_test_table.down.sql
DEBUG Found migration to revert: 1466066603_create_another_table.up.sql
DEBUG Running down migration: /home/euan/migrate.nim/migrations/1466066603_create_another_table.down.sql
DEBUG Found migration to revert: 1466067184_create_another_table_2.up.sql
DEBUG Running down migration: /home/euan/migrate.nim/migrations/1466067184_create_another_table_2.down.sql
DEBUG Found migration to revert: 1466067778_create_a_table.up.sql
DEBUG Running down migration: /home/euan/migrate.nim/migrations/1466067778_create_a_table.down.sql
INFO Reverted all ran migrations, 4 migrations undone
```

### Package

The migrate package revolves primary around a single object, the `Migrator`:

```nim
import migrate

# The path which migration files reside under.
let migrationsPath = "./migrations"
let connectionSettings = ConnectionSettings(connectionType: ConnectionType.mysql, server: "localhost", username: "root", password: "", db: "test")

let migrator = initMigrator(migrationsPath, connectionSettings)
```

You can then create migrations, run them, revert them and clean them:

```nim
let createdMigration = migrator.createMigration("create_a_table")
# createdMigration is a tuple of up and down strings, pointing to the created file paths

let upResult = migrator.up()
# upResult is a tuple of the number of ran migrations and the batch number

let downResult = migrator.down()
# downResult is a tuple of the number of reverted migrations and the batch number that was reverted

let cleanResult = migrator.clean()
# cleanResult is a tuple of the number of reverted migrations, and the batch number which is always 0
```

## TODO List

- [x] Create migrations, run them, revert them and clean them
- [x] MySQL driver to work with MySQL databases
- [x] Generator to generate migration files from existing databases
- [ ] Drivers for other database engines, including SQLite and PostgreSQL

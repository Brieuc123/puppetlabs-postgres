# @summary Define for conveniently creating a role, database and assigning the correctpermissions.
#
# @param user User to assign access to the database upon creation (will be created if not defined elsewhere). Mandatory.
# @param password Sets the password for the created user (if a user is created).
# @param comment Defines a comment to be stored about the database using the PostgreSQL COMMENT command.
# @param dbname Sets the name of the database to be created.
# @param encoding Overrides the character set during creation of the database.
# @param locale Overrides the locale during creation of the database.
# @param grant Specifies the permissions to grant during creation. Default value: 'ALL'.
# @param tablespace Defines the name of the tablespace to allocate the created database to.
# @param template Specifies the name of the template database from which to build this database. Defaults value: template0.
# @param istemplate Specifies that the database is a template, if set to true.
# @param owner Sets a user as the owner of the database.
define postgresql::server::db (
  String[1]                                    $user,
  Optional[Variant[String, Sensitive[String]]] $password   = undef,
  Optional[String[1]]                          $comment    = undef,
  String[1]                                    $dbname     = $title,
  Optional[String[1]]                          $encoding   = $postgresql::server::encoding,
  Optional[String[1]]                          $locale     = $postgresql::server::locale,
  Variant[String[1], Array[String[1]]]         $grant      = 'ALL',
  Optional[String[1]]                          $tablespace = undef,
  String[1]                                    $template   = 'template0',
  Boolean                                      $istemplate = false,
  Optional[String[1]]                          $owner      = undef
) {
  if ! defined(Postgresql::Server::Database[$dbname]) {
    postgresql::server::database { $dbname:
      comment    => $comment,
      encoding   => $encoding,
      tablespace => $tablespace,
      template   => $template,
      locale     => $locale,
      istemplate => $istemplate,
      owner      => $owner,
    }
  }

  if ! defined(Postgresql::Server::Role[$user]) {
    postgresql::server::role { $user:
      password_hash => $password,
      before        => Postgresql::Server::Database[$dbname],
    }
  }

  if ! defined(Postgresql::Server::Database_grant["GRANT ${user} - ${grant} - ${dbname}"]) {
    postgresql::server::database_grant { "GRANT ${user} - ${grant} - ${dbname}":
      privilege => $grant,
      db        => $dbname,
      role      => $user,
    } -> Postgresql_conn_validator<| db_name == $dbname |>
  }

  if ($tablespace != undef and defined(Postgresql::Server::Tablespace[$tablespace])) {
    Postgresql::Server::Tablespace[$tablespace] -> Postgresql::Server::Database[$name]
  }
}

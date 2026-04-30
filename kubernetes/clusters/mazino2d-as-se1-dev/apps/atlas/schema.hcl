schema "public" {}

table "atlas_test_users" {
  schema = schema.public

  column "id" {
    type = bigint
    null = false
  }

  column "email" {
    type = varchar(255)
    null = false
  }

  primary_key {
    columns = [column.id]
  }

  index "atlas_test_users_email_key" {
    unique  = true
    columns = [column.email]
  }
}

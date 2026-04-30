schema "public" {}

table "hotrod_trips" {
  schema = schema.public

  column "id" {
    type = bigint
    null = false
  }

  column "customer_name" {
    type = varchar(255)
    null = false
  }

  column "driver_name" {
    type = varchar(255)
    null = false
  }

  column "route" {
    type = varchar(255)
    null = false
  }

  column "status" {
    type = varchar(32)
    null = false
  }

  column "created_at" {
    type = timestamptz
    null = false
    default = sql("CURRENT_TIMESTAMP")
  }

  primary_key {
    columns = [column.id]
  }

  index "hotrod_trips_status_idx" {
    columns = [column.status]
  }
}

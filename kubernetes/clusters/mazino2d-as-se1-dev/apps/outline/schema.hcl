# Managed by the Atlas operator. Outline owns the "public" schema (its own
# Sequelize migrations), so custom objects live in a dedicated schema that
# Atlas is scoped to and never touches "public".
schema "outline_ext" {
  comment = "Custom objects managed outside of Outline"
}

table "document_bookmarks" {
  schema  = schema.outline_ext
  comment = "Per-user bookmarks of Outline documents"

  column "id" {
    type = bigint
    null = false
    identity {
      generated = ALWAYS
    }
  }

  column "user_id" {
    type    = uuid
    null    = false
    comment = "References public.users.id (not enforced across schemas)"
  }

  column "document_id" {
    type    = uuid
    null    = false
    comment = "References public.documents.id (not enforced across schemas)"
  }

  column "note" {
    type = text
    null = true
  }

  column "created_at" {
    type    = timestamptz
    null    = false
    default = sql("CURRENT_TIMESTAMP")
  }

  primary_key {
    columns = [column.id]
  }

  index "document_bookmarks_user_document_key" {
    unique  = true
    columns = [column.user_id, column.document_id]
  }

  index "document_bookmarks_document_id_idx" {
    columns = [column.document_id]
  }
}

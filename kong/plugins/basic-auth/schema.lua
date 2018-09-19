local typedefs = require "kong.db.schema.typedefs"

return {
  name = "basic-auth",
  fields = {
    { consumer = typedefs.no_consumer },
    { config = {
        type = "record",
        nullable = false,
        fields = {
          { anonymous = { type = "string", uuid = true, len_min = 0, default = "" }, },
          { hide_credentials = { type = "boolean", default = false }, },
    }, }, },
  },
}

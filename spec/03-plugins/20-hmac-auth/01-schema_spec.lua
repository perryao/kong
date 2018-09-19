local Schema = require "kong.db.schema"
local plugins_schema_def = require "kong.db.schema.entities.plugins"
local schema_def = require "kong.plugins.hmac-auth.schema"

local plugins_schema = assert(Schema.new(plugins_schema_def))
assert(plugins_schema:new_subschema(schema_def.name, schema_def))


local function validate_config(config)
  return plugins_schema:validate_insert({
    name = schema_def.name,
    config = config
  })
end

describe("Plugin: hmac-auth (schema)", function()
  it("accepts empty config", function()
    local ok, err = validate_config({})
    assert.is_truthy(ok)
    assert.is_nil(err)
  end)
  it("accepts correct clock skew", function()
    local ok, err = validate_config({ clock_skew = 10 })
    assert.is_truthy(ok)
    assert.is_nil(err)
  end)
  it("errors with negative clock skew", function()
    local ok, err = validate_config({ clock_skew = -10 })
    assert.is_falsy(ok)
    assert.equal("value must be greater than 0", err.config.clock_skew)
  end)
  it("errors with wrong algorithm", function()
    local ok, err = validate_config({ algorithms = { "sha1024" } })
    assert.is_falsy(ok)
    assert.equal("expected one of: hmac-sha1, hmac-sha256, hmac-sha384, hmac-sha512",
                 err.config.algorithms)
  end)
end)

local Schema = require "kong.db.schema"
local plugins_schema_def = require "kong.db.schema.entities.plugins"
local schema_def = require "kong.plugins.request-transformer.schema"

local plugins_schema = assert(Schema.new(plugins_schema_def))
assert(plugins_schema:new_subschema(schema_def.name, schema_def))

local function validate_config(config)
  return plugins_schema:validate_insert({
    name = schema_def.name,
    config = config
  })
end


describe("Plugin: request-transformer (schema)", function()
  it("validates http_method", function()
    local ok, err = validate_config({ http_method = "GET" })
    assert.True(ok)
    assert.is_nil(err)
  end)
  it("errors invalid http_method", function()
    local ok, err = validate_config({ http_method = "HELLO!" })
    assert.Falsy(ok)
    assert.equal("invalid value: HELLO!", err.config.http_method)
  end)
end)

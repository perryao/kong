local Schema = require "kong.db.schema"
local plugins_schema_def = require "kong.db.schema.entities.plugins"
local schema_def = require "kong.plugins.jwt.schema"

local plugins_schema = assert(Schema.new(plugins_schema_def))
assert(plugins_schema:new_subschema(schema_def.name, schema_def))

local function validate_config(config)
  return plugins_schema:validate_insert({
    name = schema_def.name,
    config = config
  })
end

describe("Plugin: jwt (schema)", function()
  it("validates 'maximum_expiration'", function()
    local ok, err = validate_config({
      maximum_expiration = 60,
      claims_to_verify = { "exp", "nbf" },
    })

    assert.is_nil(err)
    assert.is_true(ok)
  end)

  describe("errors", function()
    it("when 'maximum_expiration' is negative", function()
      local ok, err = validate_config({
        maximum_expiration = -1,
        claims_to_verify = { "exp", "nbf" },
      })

      assert.is_falsy(ok)
      assert.same({
        maximum_expiration = "value should be between 0 and 31536000"
      }, err.config)

      local ok, err = validate_config({
        maximum_expiration = -1,
        claims_to_verify = { "nbf" },
      })

      assert.is_falsy(ok)
      assert.same({
        maximum_expiration = "value should be between 0 and 31536000"
      }, err.config)
    end)

    it("when 'maximum_expiration' is specified without 'exp' in 'claims_to_verify'", function()
      local ok, err = validate_config({
        maximum_expiration = 60,
        claims_to_verify = { "nbf" },
      })

      assert.is_falsy(ok)
      assert.equals("expected to contain: exp", err.config.claims_to_verify)
    end)
  end)
end)

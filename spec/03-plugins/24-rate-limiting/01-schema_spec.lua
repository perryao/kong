local Schema = require "kong.db.schema"
local plugins_schema_def = require "kong.db.schema.entities.plugins"
local schema_def = require "kong.plugins.rate-limiting.schema"

local plugins_schema = assert(Schema.new(plugins_schema_def))
assert(plugins_schema:new_subschema(schema_def.name, schema_def))


local function validate_config(config)
  return plugins_schema:validate_insert({
    name = schema_def.name,
    config = config
  })
end


describe("Plugin: rate-limiting (schema)", function()
  it("proper config validates", function()
    local config = { second = 10 }
    local ok, _, err = validate_config(config)
    assert.truthy(ok)
    assert.is_nil(err)
  end)
  it("proper config validates (bis)", function()
    local config = { second = 10, minute = 20, hour = 30, day = 40, month = 50, year = 60 }
    local ok, _, err = validate_config(config)
    assert.truthy(ok)
    assert.is_nil(err)
  end)

  describe("errors", function()
    it("limits: smaller unit is less than bigger unit", function()
      local config = { second = 20, hour = 10 }
      local ok, err = validate_config(config)
      assert.falsy(ok)
      assert.equal("The limit for hour(10.0) cannot be lower than the limit for second(20.0)", err.config)
    end)
    it("limits: smaller unit is less than bigger unit (bis)", function()
      local config = { second = 10, minute = 20, hour = 30, day = 40, month = 60, year = 50 }
      local ok, err = validate_config(config)
      assert.falsy(ok)
      assert.equal("The limit for year(50.0) cannot be lower than the limit for month(60.0)", err.config)
    end)

    it("invalid limit", function()
      local config = {}
      local ok, err = validate_config(config)
      assert.falsy(ok)
      assert.same({"at least one of these fields must be non-empty: 'config.second', 'config.minute', 'config.hour', 'config.day', 'config.month', 'config.year'" },
                  err["@entity"])
    end)
  end)
end)

local Schema = require "kong.db.schema"
local plugins_schema_def = require "kong.db.schema.entities.plugins"
local schema_def = require "kong.plugins.ip-restriction.schema"

local plugins_schema = assert(Schema.new(plugins_schema_def))
assert(plugins_schema:new_subschema(schema_def.name, schema_def))

local function v(config)
  return plugins_schema:validate_insert({
    name = schema_def.name,
    config = config
  })
end


describe("Plugin: ip-restriction (schema)", function()
  it("should accept a valid whitelist", function()
    assert(v({ whitelist = { "127.0.0.1", "127.0.0.2" } }))
  end)
  it("should accept a valid blacklist", function()
    assert(v({ blacklist = { "127.0.0.1", "127.0.0.2" } }))
  end)

  describe("errors", function()
    it("whitelist should not accept invalid types", function()
      local ok, err = v({ whitelist = 12 })
      assert.falsy(ok)
      assert.same({ whitelist = "expected an array" }, err.config)
    end)
    it("whitelist should not accept invalid IPs", function()
      local ok, err = v({ whitelist = { "hello" } })
      assert.falsy(ok)
      assert.same({ whitelist = "cannot parse 'hello': Invalid IP" }, err.config)

      ok, err = v({ whitelist = { "127.0.0.1", "127.0.0.2", "hello" } })
      assert.falsy(ok)
      assert.same({ whitelist = "cannot parse 'hello': Invalid IP" }, err.config)
    end)
    it("blacklist should not accept invalid types", function()
      local ok, err = v({ blacklist = 12 })
      assert.falsy(ok)
      assert.same({ blacklist = "expected an array" }, err.config)
    end)
    it("blacklist should not accept invalid IPs", function()
      local ok, err = v({ blacklist = { "hello" } })
      assert.falsy(ok)
      assert.same({ blacklist = "cannot parse 'hello': Invalid IP" }, err.config)

      ok, err = v({ blacklist = { "127.0.0.1", "127.0.0.2", "hello" } })
      assert.falsy(ok)
      assert.same({ blacklist = "cannot parse 'hello': Invalid IP" }, err.config)
    end)
    it("should not accept both a whitelist and a blacklist", function()
      local t = { blacklist = { "127.0.0.1" }, whitelist = { "127.0.0.2" } }
      local ok, err = v(t)
      assert.falsy(ok)
      assert.same({ "only one of these fields must be non-empty: 'config.whitelist', 'config.blacklist'" }, err["@entity"])
    end)
    it("should not accept both empty whitelist and blacklist", function()
      local t = { blacklist = {}, whitelist = {} }
      local ok, err = v(t)
      assert.falsy(ok)
      local expected = {
        "only one of these fields must be non-empty: 'config.whitelist', 'config.blacklist'",
        "at least one of these fields must be non-empty: 'config.whitelist', 'config.blacklist'",
      }
      assert.same(expected, err["@entity"])
    end)
  end)
end)

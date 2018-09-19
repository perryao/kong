local Schema = require "kong.db.schema"
local plugins_schema_def = require "kong.db.schema.entities.plugins"
local schema_def = require "kong.plugins.request-termination.schema"

local plugins_schema = assert(Schema.new(plugins_schema_def))
assert(plugins_schema:new_subschema(schema_def.name, schema_def))


local function v(config)
  return plugins_schema:validate_insert({
    name = schema_def.name,
    config = config
  })
end


describe("Plugin: request-termination (schema)", function()
  it("should accept a valid status_code", function()
    assert(v({status_code = 404}))
  end)
  it("should accept a valid message", function()
    assert(v({message = "Not found"}))
  end)
  it("should accept a valid content_type", function()
    assert(v({content_type = "text/html",body = "<body><h1>Not found</h1>"}))
  end)
  it("should accept a valid body", function()
    assert(v({body = "<body><h1>Not found</h1>"}))
  end)

  describe("errors", function()
    it("status_code should only accept numbers", function()
      local ok, err = v({status_code = "abcd"})
      assert.falsy(ok)
      assert.same("expected an integer", err.config.status_code)
    end)
    it("status_code < 100", function()
      local ok, err = v({status_code = 99})
      assert.falsy(ok)
      assert.same("value should be between 100 and 599", err.config.status_code)
    end)
    it("status_code > 599", function()
      local ok,err = v({status_code = 600})
      assert.falsy(ok)
      assert.same("value should be between 100 and 599", err.config.status_code)
    end)
    it("#message with body", function()
      local ok, err = v({message = "error", body = "test"})
      assert.falsy(ok)
      assert.same("message cannot be used with content_type or body", err.config)
    end)
    it("message with body and content_type", function()
      local ok, err = v({message = "error", content_type="text/html", body = "test"})
      assert.falsy(ok)
      assert.same("message cannot be used with content_type or body", err.config)
    end)
    it("message with content_type", function()
      local ok, err = v({message = "error", content_type="text/html"})
      assert.falsy(ok)
      assert.same("message cannot be used with content_type or body", err.config)
    end)
    it("content_type without body", function()
      local ok, err = v({content_type="text/html"})
      assert.falsy(ok)
      assert.same("content_type requires a body", err.config)
    end)
  end)
end)

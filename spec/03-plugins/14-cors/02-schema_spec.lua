local Schema = require "kong.db.schema"
local plugins_schema_def = require "kong.db.schema.entities.plugins"
local cors_schema_def = require "kong.plugins.cors.schema"

local plugins_schema = assert(Schema.new(plugins_schema_def))
assert(plugins_schema:new_subschema("cors", cors_schema_def))


local function validate_config(config)
  return plugins_schema:validate_insert({
    name = "cors",
    config = config
  })
end


describe("cors schema", function()
  it("validates '*'", function()
    local ok, err = validate_config({ origins = { "*" } })

    assert.True(ok)
    assert.is_nil(err)
  end)

  it("validates what looks like a domain", function()
    local ok, err = validate_config({ origins = { "example.com" } })

    assert.True(ok)
    assert.is_nil(err)
  end)

  it("validates what looks like a regex", function()
    local ok, err = validate_config({ origins = { [[.*\.example(?:-foo)?\.com]] } })

    assert.True(ok)
    assert.is_nil(err)
  end)

  describe("errors", function()
    it("with invalid regex in origins", function()
      local mock_origins = { [[.*.example.com]], [[invalid_**regex]] }
      local ok, err = validate_config({ origins = mock_origins })

      assert.Falsy(ok)
      assert.equals("'invalid_**regex' is not a valid regex",
                    err.config.origins)
    end)
  end)
end)

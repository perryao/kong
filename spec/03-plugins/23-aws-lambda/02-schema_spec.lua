local utils = require "kong.tools.utils"
local Schema = require "kong.db.schema"
local plugins_schema_def = require "kong.db.schema.entities.plugins"
local schema_def = require "kong.plugins.aws-lambda.schema"

local plugins_schema = assert(Schema.new(plugins_schema_def))
assert(plugins_schema:new_subschema(schema_def.name, schema_def))

local DEFAULTS = {
  timeout          = 60000,
  keepalive        = 60000,
  aws_key          = "my-key",
  aws_secret       = "my-secret",
  aws_region       = "us-east-1",
  function_name    = "my-function",
  invocation_type  = "RequestResponse",
  log_type         = "Tail",
  port             = 443,
}

local function validate_config(config)
  return plugins_schema:validate_insert({
    name = schema_def.name,
    config = utils.table_merge(DEFAULTS, config)
  })
end


describe("Plugin: AWS Lambda (schema)", function()


  it("accepts nil Unhandled Response Status Code", function()
    local ok, err = validate_config({ unhandled_status = nil })
    assert.truthy(ok)
    assert.is_nil(err)
  end)

  it("accepts correct Unhandled Response Status Code", function()
    local ok, err = validate_config({ unhandled_status = 412 })
    assert.truthy(ok)
    assert.is_nil(err)
  end)

  it("errors with Unhandled Response Status Code less than 100", function()
    local ok, err = validate_config({ unhandled_status = 99 })
    assert.falsy(ok)
    assert.equal("value should be between 100 and 999", err.config.unhandled_status)
  end)

  it("errors with Unhandled Response Status Code greater than 999", function()
    local ok, err = validate_config({ unhandled_status = 1000 })
    assert.falsy(ok)
    assert.equal("value should be between 100 and 999", err.config.unhandled_status)
  end)
end)

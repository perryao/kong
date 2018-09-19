local Schema = require "kong.db.schema"
local plugins_schema_def = require "kong.db.schema.entities.plugins"
local schema_def = require "kong.plugins.datadog.schema"

local plugins_schema = assert(Schema.new(plugins_schema_def))
assert(plugins_schema:new_subschema(schema_def.name, schema_def))


local function validate_config(config)
  return plugins_schema:validate_insert({
    name = schema_def.name,
    config = config
  })
end


describe("Plugin: datadog (schema)", function()
  it("accepts empty config #o", function()
    local ok, err = validate_config({})
    assert.is_nil(err)
    assert.is_true(ok)
  end)
  it("accepts empty metrics", function()
    local metrics_input = {}
    local ok, err = validate_config({ metrics = metrics_input})
    assert.is_nil(err)
    assert.is_true(ok)
  end)
  it("accepts just one metrics", function()
    local metrics_input = {
      {
        name = "request_count",
        stat_type = "counter",
        sample_rate = 1,
        tags = {"K1:V1"}
      }
    }
    local ok, err = validate_config({ metrics = metrics_input})
    assert.is_nil(err)
    assert.is_true(ok)
  end)
  it("rejects if name or stat not defined", function()
    local metrics_input = {
      {
        name = "request_count",
        sample_rate = 1
      }
    }
    local _, err = validate_config({ metrics = metrics_input })
    assert.same({ stat_type = "required field missing" }, err.config.metrics)
    local metrics_input = {
      {
        stat_type = "counter",
        sample_rate = 1
      }
    }
    _, err = validate_config({ metrics = metrics_input})
    assert.same("required field missing", err.config.metrics.name)
  end)
  it("rejects counters without sample rate", function()
    local metrics_input = {
      {
        name = "request_count",
        stat_type = "counter",
      }
    }
    local _, err = validate_config({ metrics = metrics_input})
    assert.not_nil(err)
  end)
  it("rejects invalid metrics name", function()
    local metrics_input = {
      {
        name = "invalid_name",
        stat_type = "counter",
      }
    }
    local _, err = validate_config({ metrics = metrics_input})
    assert.match("expected one of: kong_latency", err.config.metrics.name)
    assert.equal("required field missing", err.config.metrics.sample_rate)
  end)
  it("rejects invalid stat type", function()
    local metrics_input = {
      {
        name = "request_count",
        stat_type = "invalid_stat",
      }
    }
    local _, err = validate_config({ metrics = metrics_input})
    assert.match("expected one of: counter", err.config.metrics.stat_type)
  end)
  it("rejects if customer identifier missing", function()
    local metrics_input = {
      {
        name = "status_count_per_user",
        stat_type = "counter",
        sample_rate = 1
      }
    }
    local _, err = validate_config({ metrics = metrics_input })
    assert.equals("required field missing", err.config.metrics.consumer_identifier)
  end)
  it("rejects if metric has wrong stat type", function()
    local metrics_input = {
      {
        name = "unique_users",
        stat_type = "counter"
      }
    }
    local _, err = validate_config({ metrics = metrics_input})
    assert.not_nil(err)
    assert.equal("value must be counter", err.config.metrics.stat_type)
    metrics_input = {
      {
        name = "status_count",
        stat_type = "set",
        sample_rate = 1
      }
    }
    _, err = validate_config({ metrics = metrics_input})
    assert.not_nil(err)
    assert.equal("value must be set", err.config.metrics.stat_type)
  end)
  it("rejects if tags malformed", function()
    local metrics_input = {
      {
        name = "status_count",
        stat_type = "counter",
        sample_rate = 1,
        tags = {"T1:"}
      }
    }
    local _, err = validate_config({ metrics = metrics_input})
    assert.same({ tags = "invalid value: T1:" }, err.config.metrics)
  end)
  it("accept if tags is aempty list", function()
    local metrics_input = {
      {
        name = "status_count",
        stat_type = "counter",
        sample_rate = 1,
        tags = {}
      }
    }
    local _, err = validate_config({ metrics = metrics_input})
    assert.is_nil(err)
  end)
end)

local helpers         = require "spec.helpers"
local validate_entity = require("kong.dao.schemas_validation").validate_entity
local oauth2_daos     = require "kong.plugins.oauth2.daos"
local utils           = require "kong.tools.utils"

local oauth2_authorization_codes_schema = oauth2_daos.oauth2_authorization_codes

local fmt = string.format

for _, strategy in helpers.each_strategy() do
  describe(fmt("Plugin: oauth2 [#%s] (schema)", strategy), function()
    local bp, db, dao = helpers.get_db_utils(strategy)

    local validate_config = function(config)
      local plugins_schema = db.plugins.schema
      local entity_to_insert, err = plugins_schema:process_auto_fields({
        id = "b5e7b55e-cd5e-47ef-952d-ba1754dbf18e",
        name = "oauth2",
        config = config
      })
      if err then
        return nil, err
      end
      local _, err = plugins_schema:validate_insert(entity_to_insert)
      if err then return
        nil, err
      end
      return entity_to_insert
    end

    it("does not require `scopes` when `mandatory_scope` is false", function()
      local ok, errors = validate_config({enable_authorization_code = true, mandatory_scope = false})
      assert.is_truthy(ok)
      assert.is_falsy(errors)
    end)
    it("valid when both `scopes` when `mandatory_scope` are given", function()
      local ok, errors = validate_config({enable_authorization_code = true, mandatory_scope = true, scopes = {"email", "info"}})
      assert.truthy(ok)
      assert.is_falsy(errors)
    end)
    it("autogenerates `provision_key` when not given", function()
      local t = {enable_authorization_code = true, mandatory_scope = true, scopes = {"email", "info"}}
      local t2, errors = validate_config(t)
      assert.is_falsy(errors)
      assert.truthy(t2.config.provision_key)
      assert.equal(32, t2.config.provision_key:len())
    end)
    it("does not autogenerate `provision_key` when it is given", function()
      local t = {enable_authorization_code = true, mandatory_scope = true, scopes = {"email", "info"}, provision_key = "hello"}
      local ok, errors = validate_config(t)
      assert.truthy(ok)
      assert.is_falsy(errors)
      assert.truthy(t.provision_key)
      assert.equal("hello", t.provision_key)
    end)
    it("sets default `auth_header_name` when not given", function()
      local t = {enable_authorization_code = true, mandatory_scope = true, scopes = {"email", "info"}}
      local t2, errors = validate_config(t)
      assert.truthy(t2)
      assert.is_falsy(errors)
      assert.truthy(t2.config.provision_key)
      assert.equal(32, t2.config.provision_key:len())
      assert.equal("authorization", t2.config.auth_header_name)
    end)
    it("does not set default value for `auth_header_name` when it is given", function()
      local t = {enable_authorization_code = true, mandatory_scope = true, scopes = {"email", "info"}, provision_key = "hello",
      auth_header_name="custom_header_name"}
      local t2, errors = validate_config(t)
      assert.truthy(t2)
      assert.is_falsy(errors)
      assert.truthy(t2.config.provision_key)
      assert.equal("hello", t2.config.provision_key)
      assert.equal("custom_header_name", t2.config.auth_header_name)
    end)
    it("sets refresh_token_ttl to default value if not set", function()
      local t = {enable_authorization_code = true, mandatory_scope = false}
      local t2, errors = validate_config(t)
      assert.truthy(t2)
      assert.is_falsy(errors)
      assert.equal(1209600, t2.config.refresh_token_ttl)
    end)

    describe("errors", function()
      it("requires at least one flow", function()
        local ok, err = validate_config({})
        assert.is_falsy(ok)

        assert.same("at least one of these fields must be true: enable_authorization_code, enable_implicit_grant, enable_client_credentials, enable_password_grant",
                     err.config)
      end)
      it("requires `scopes` when `mandatory_scope` is true", function()
        local ok, err = validate_config({enable_authorization_code = true, mandatory_scope = true})
        assert.is_falsy(ok)
        assert.equal("required field missing",
                     err.config.scopes)
      end)

      it("errors when given an invalid service_id on oauth authorization codes", function()
        local service = bp.services:insert()
        local u = utils.uuid()

        local ok, err, err_t = validate_entity({
          credential_id = "foo",
          service_id = "bar",
        }, oauth2_authorization_codes_schema, { dao = dao })
        assert.is_falsy(ok)
        assert.is_falsy(err)
        assert.equals(err_t.tbl.fields.id, "expected a valid UUID")

        local ok, err, err_t = validate_entity({
          credential_id = "foo",
          service_id = u,
        }, oauth2_authorization_codes_schema, { dao = dao })
        assert.is_falsy(ok)
        assert.is_falsy(err)
        assert.equals(err_t.message, fmt("no such Service (id=%s)", u))

        local ok, err, err_t = validate_entity({
          credential_id = "foo",
          service_id = service.id,
        }, oauth2_authorization_codes_schema, { dao = dao })

        assert.truthy(ok)
        assert.is_falsy(err)
        assert.is_falsy(err_t)
      end)
    end)

    describe("when deleting a service", function()
      it("deletes associated oauth2 entities", function()
        local service = bp.services:insert()
        local consumer = bp.consumers:insert()
        local credential = bp.oauth2_credentials:insert({
          redirect_uri = "http://example.com",
          consumer_id = consumer.id,
        })

        local ok, err, err_t

        local token = bp.oauth2_tokens:insert({
          credential_id = credential.id,
          service_id = service.id,
        })
        local code = bp.oauth2_authorization_codes:insert({
          credential_id = credential.id,
          service_id = service.id,
        })

        token, err = dao.oauth2_tokens:find(token)
        assert.falsy(err)
        assert.truthy(token)

        code, err = dao.oauth2_authorization_codes:find(code)
        assert.falsy(err)
        assert.truthy(code)


        ok, err, err_t = db.services:delete({ id = service.id })
        assert.truthy(ok)
        assert.is_falsy(err_t)
        assert.is_falsy(err)

        -- no more service
        service, err = db.services:select({ id = service.id })
        assert.falsy(err)
        assert.falsy(service)

        -- no more token
        token, err = dao.oauth2_tokens:find({ id = token.id })
        assert.falsy(err)
        assert.falsy(token)

        -- no more code
        local code, err = dao.oauth2_authorization_codes:find({ id = code.id })
        assert.falsy(err)
        assert.falsy(code)
      end)
    end)
  end)
end

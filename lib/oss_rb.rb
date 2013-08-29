require 'rest_client'
require 'active_support/all'

module Oss
  class Index
    attr_accessor :documents, :name
    def initialize(name, host = 'http://localhost:8080', login = nil, key = nil)
      @name = name
      @documents = Array.new
      @host = host
      @credentials = {:login=>login,:key=>key}
    end

    # Return the index list
    # http://github.com/jaeksoft/opensearchserver/wiki/Index-list
    def list
      JSON.parse(api_get("services/rest/index"))["indexList"]
    end

    # Create a new index with the given template name
    # http://github.com/jaeksoft/opensearchserver/wiki/Index-create
    def create(template = 'WEB_CRAWLER')
      api_post "services/rest/index/#{@name}/template/#{template}"
    end

    # Delete the index
    # http://github.com/jaeksoft/opensearchserver/wiki/Index-delete
    def delete!
      api_delete "services/rest/index/#{@name}"
    end

    # Create or update the field defined by the given hash
    # http://github.com/jaeksoft/opensearchserver/wiki/Field-create-update
    def set_field(field_params)
      api_put_json "services/rest/index/#{@name}/field", field_params
    end

    # Set the default field and the unique field
    # http://github.com/jaeksoft/opensearchserver/wiki/Field-set-default-unique
    def set_field_default_unique(default, unique)
      params = { 'unique' => unique, 'default' => default }
      api_put "services/rest/index/#{@name}/field", '', params
    end

    # Delete the field matching the give name
    # http://github.com/jaeksoft/opensearchserver/wiki/Field-delete
    def delete_field(field_name = nil)
      api_delete "services/rest/index/#{@name}/field/#{field_name}"
    end

    # Delete the document matching the given field and values
    # http://github.com/jaeksoft/opensearchserver/wiki/Document-delete
    def delete_document_by_value(field_name, *values)
      api_delete "services/rest/index/#{@name}/document/#{field_name}/#{values.join('/')}"
    end

    # Delete the document matching the given query
    def delete_document_by_query(query)
      params = { 'query' => query }
      api_delete "services/rest/index/#{@name}/document", params
    end

    # Put document in the index
    # http://github.com/jaeksoft/opensearchserver/wiki/Document-put-JSON
    def index!
      api_put_json "services/rest/index/#{@name}/document", @documents
    end

    # Execute a search (using pattern)
    def search_pattern( body = nil)
      JSON.parse(api_post_json("services/rest/index/#{@name}/search/pattern", body))
    end

    # Execute a search (using field)
    # http://github.com/jaeksoft/opensearchserver/wiki/Search-field
    def search_field(body = nil)
      JSON.parse(api_post_json("services/rest/index/#{@name}/search/field", body))
    end

    # Execute a search based on an existing template
    # http://github.com/jaeksoft/opensearchserver/wiki/Search-pattern
    def search_template_pattern(template,  body = nil)
      JSON.parse(api_post_json("services/rest/index/#{@name}/search/pattern/#{template}", body))
    end

    # Execute a search based on an existing template
    # http://github.com/jaeksoft/opensearchserver/wiki/Search-template-field
    def search_template_field(template,  body = nil)
      JSON.parse(api_post_json("services/rest/index/#{@name}/search/field/#{template}", body))
    end

    # Create/update a search template (pattern search)
    # http://github.com/jaeksoft/opensearchserver/wiki/Search-template-pattern-set
    def search_store_template_pattern(template,  body = nil)
      api_put_json "services/rest/index/#{@name}/search/pattern/#{template}", body
    end

    # Create/update a search template (field search)
    # http://github.com/jaeksoft/opensearchserver/wiki/Search-template-field-set
    def search_store_template_field(template,  body = nil)
      api_put_json"services/rest/index/#{@name}/search/field/#{template}", body
    end

    # Delete a search template matching the given name
    # http://github.com/jaeksoft/opensearchserver/wiki/Search-template-delete
    def search_template_delete(template)
      api_delete "services/rest/index/#{@name}/search/template/#{template}"
    end

    private

    def api_get (method, params={})
      RestClient.get("#{@host}/#{method}", {:accept => :json, :params => params})
    end

    def api_post (method, body="", params={})
      RestClient.post("#{@host}/#{method}", body, {:params => params.merge(@credentials)})
    end

    def api_post_json (method, body="", params={})
      RestClient.post("#{@host}/#{method}", body.to_json, {:accept => :json, :content_type => :json, :params => params.merge(@credentials)})
    end

    def api_put (method, body="", params={})
      RestClient.put("#{@host}/#{method}", body, {:params => params.merge(@credentials)})
    end

    def api_put_json (method, body="", params={})
      RestClient.put("#{@host}/#{method}", body.to_json, {:accept => :json, :content_type => :json, :params => params.merge(@credentials)})
    end

    def api_delete (method, params={})
      RestClient.delete("#{@host}/#{method}", {:params => params.merge(@credentials)})
    end

  end

  class Field
    attr_accessor :name, :value, :boost
    def initialize(name, value, boost=1.0)
      @name = name
      @value = value
      @boost =boost
    end
  end

  class Document < Field
    attr_accessor :lang, :fields
    def initialize(lang ='ENGLISH')
      @lang = lang
      @fields = Array.new
    end
  end

end

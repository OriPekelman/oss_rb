require 'nokogiri'
require 'rest_client'

require_relative '../vendor/nokogiri_to_hash'

module Oss
  class Index
    attr_accessor :documents, :name, :search_result
    def initialize(name, host = 'http://localhost:8080/oss-1.5', login = nil, key = nil)
      @name = name
      @documents = []
      @host ||= host
      @credentials = {:login=>login,:key=>key}
    end

    def list
      response = Nokogiri::XML(api_get "#{@host}/schema", {:cmd => 'indexlist'} )
      response.css('index').map{|i|i.attributes['name'].value}
    end

    def create(template = 'WEB_CRAWLER')
      params = {
        'cmd' => 'createindex',
        'index.name' => @index_name,
        'index.template' => template
      }
      api_get "#{@host}/schema", params
    end

    def delete!
      params = {
        'cmd' => 'deleteindex',
        'index.name' => @index_name
      }
      api_get "#{@host}/schema", params
    end

    def set_field(default = false, unique = false, name = nil, analyzer = nil, stored = true, indexed = true, termVector = nil)
      params = {
        'cmd' => 'setfield',
        'use' => @index_name,
        'field.default' => default ? 'yes' : 'no',
        'field.unique' => unique ? 'yes' : 'no',
        'field.name' => name,
        'field.analyzer' => analyzer,
        'field.stored' => stored ? 'yes' : 'no',
        'field.indexed' => indexed ? 'yes' : 'no' ,
        'field.termVector' => termVector
      }
      api_get "#{@host}/schema", params
    end

    def delete_field(name = nil)
      params = {
        'cmd' => 'deletefield',
        'use' => @index_name,
        'field.name' => name,
      }
      api_get "#{@host}/schema", params
    end

    def add_document(doc)
      if doc.is_a?(Array) then
        @documents = doc
      else
        @documents << doc
      end
    end

    def index!
      params = {
        'use' => @index_name
      }
      api_post "#{@host}/update", self.to_xml, params
    end

    # Populate the query string with values in an hash.
    # Array of value is added as multiple key/value
    def self.multikey_querystring(qs_key, value)
      parm = ''
      if value != nil then
        if value.is_a?Array then
          value.each do |v|
            parm += '&' + qs_key + '=' + URI::encode(v.to_s)
          end
        else
          parm += '&' + qs_key + '=' + URI::encode(value.to_s)
        end
      end
      return parm
    end

    # Populate the query string with a non nil value
    def self.singlekey_querystring(qs_key, value)
      parm = ''
      if value != nil then
        parm += '&' + qs_key + '=' + URI::encode(value.to_s)
      end
      return parm
    end

    def search(query,  params = nil)
      # The query string is build manually to handle multiple value with the same key
      querystring = 'use=' + URI::encode(@name)
      querystring += Index.singlekey_querystring('login', @credentials[:login])
      querystring += Index.singlekey_querystring('key', @credentials[:key])
      querystring += Index.singlekey_querystring('query', query)
      # Evaluating the parameters given in the hash
      if (params != nil) then
        querystring += Index.multikey_querystring('qt', params['query_template'])
        querystring += Index.multikey_querystring('start', params['start'])
        querystring += Index.multikey_querystring('rows', params['rows'])
        querystring += Index.multikey_querystring('lang', params['lang'])
        querystring += Index.multikey_querystring('rf', params['returned_field'])
        querystring += Index.multikey_querystring('fq', params['filter_query'])
        querystring += Index.multikey_querystring('fqn', params['filter_negative_query'])
        querystring += Index.multikey_querystring('sort', params['sort'])
        querystring += Index.multikey_querystring('facet', params['facet'])
        querystring += Index.multikey_querystring('facet.multi', params['facet_multi'])
      end
      puts querystring
      xml = Nokogiri::XML(RestClient.get("#{@host}/select?#{querystring}"))
      err = xml.at_xpath('.//entry')
      if !err.nil? && err.to_str=="Error"
        puts response
        raise "API reported Error"
      else
        return xml
      end
    end

    def to_xml
      builder = Nokogiri::XML::Builder.new(:encoding => 'utf-8') do |xml|
        xml.index{
          @documents.each do |doc|
            xml.document(:lang => doc.lang){
              doc.fields.map do |f|
                xml.field(:name =>f[0]){
                  f[1].each do |v|
                    xml.value(v)
                  end
                }
              end
            }
          end
        }
      end
      builder.to_xml
    end

    private

    def api_get (method, params)
      RestClient.get(method, {:params => params.merge(@credentials)})
    end

    def api_post (method, body, params)
      RestClient.get(method, {:accept => :xml, :content_type => :xml, :params => params.merge(@credentials)})
    end

  end

  class Document
    attr_accessor :lang, :fields
    def initialize(lang ='en')
      @lang = lang
      @fields = {}
    end

    def add_field(name, value)
      if value.is_a?(Array) then
        @fields[name] = value
      else
        @fields[name] ||=[]
        @fields[name] <<  value
      end

    end
  end
end

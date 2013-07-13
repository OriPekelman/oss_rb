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
      @login = login
      @key = key
      @search_result
    end

    def list
      response = Nokogiri::XML(RestClient.get("#{@host}/schema", {:params => { :cmd => 'indexlist' }}))
      response.css('index').map{|i|i.attributes['name'].value}
    end

    def create(template = 'WEB_CRAWLER')
      params = {
        'cmd' => 'createindex',
        'login' => @login,
        'key' => @key,
        'index.name' => @name,
        'index.template' => template
      }
      RestClient.get "#{@host}/schema", {:params => params}
    end

    def delete!
      params = {
        'cmd' => 'deleteindex',
        'login' => @login,
        'key' => @key,
        'index.name' => @name
      }
      RestClient.get "#{@host}/schema",  {:params => params}
    end

    def set_field(default = false, unique = false, name = nil, analyzer = nil, stored = true, indexed = true, termVector = nil)
      params = {
        'cmd' => 'setfield',
        'login' => @login,
        'key' => @key,
        'use' => @name,
        'field.default' => default ? 'yes' : 'no',
        'field.unique' => unique ? 'yes' : 'no',
        'field.name' => name,
        'field.analyzer' => analyzer,
        'field.stored' => stored ? 'yes' : 'no',
        'field.indexed' => indexed ? 'yes' : 'no' ,
        'field.termVector' => termVector
      }
      RestClient.get "#{@host}/schema", {:params => params}
    end

    def delete_field(name = nil)
      params = {
        'cmd' => 'deletefield',
        'login' => @login,
        'key' => @key,
        'use' => @name,
        'field.name' => name,
      }
      RestClient.get "#{@host}/schema", {:params => params}
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
        'login' => @login,
        'key' => @key,
        'use' => @name
      }
      RestClient.post "#{@host}/update", self.to_xml, {:params => params, :accept => :xml, :content_type => :xml}
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
      querystring += Index.singlekey_querystring('login', @login)
      querystring += Index.singlekey_querystring('key', @key)
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
      @search_result = Nokogiri::XML(RestClient.get("#{@host}/select?#{querystring}"))
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

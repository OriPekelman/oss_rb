require 'nokogiri'
require 'rest_client'
require_relative '../vendor/nokogiri_to_hash'

module Oss
  class Index
    attr_accessor :documents, :name

    def initialize(name, host = 'http://localhost:8080', login = nil, key = nil)
      @index_name = name
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

    def search(term, lang = 'en', returned_field = nil)
      params = {
        'use' => @index_name,
        'lang' => lang,
        'query' => URI::encode(term),
        # 'qt'=>"template_1"
        #FIXME template is required?
      }
      
      params.merge!({'rf' => returned_field}) unless returned_field.nil?
      
      response = Nokogiri::XML(api_get "#{@host}/select", params )
      err = response.at_xpath('.//entry') 
      if !err.nil? && err.to_str=="Error"
        puts response
        raise "API reported Error"
      else
      response.css('result doc').map{|i|{
          :score => i.attributes["score"].value,
        }}
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

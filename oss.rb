require 'nokogiri'
require 'rest_client'

require_relative './vendor/nokogiri_to_hash'

module Oss
  class Index
    attr_accessor :documents, :name
    def initialize(name, host = 'http://localhost:8080/oss-1.5', login = nil, key = nil)
      @name = name
      @documents = []
      @host ||= host
      @login = login
      @key = key
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

    def search(term, lang = 'en', returned_field = nil)
      params = {
        'login' => @login,
        'key' => @key,
        'use' => @name,
        'lang' => lang,
        'q' => URI::encode(term),
        'rf' => returned_field
      }
      response = Nokogiri::XML(RestClient.get("#{@host}/select", {:params => params}))
      response.css('result doc').map{|i|{
          :score => i.attributes["score"].value,
        }}
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
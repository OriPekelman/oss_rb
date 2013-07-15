require 'nokogiri'
require 'rest_client'

require_relative '../vendor/nokogiri_to_hash'

module Oss
  class Index
    attr_accessor :documents, :name
    def initialize(name, host = 'http://localhost:8080', login = nil, key = nil)
      @name = name
      @documents = []
      @host = host
      @credentials = {:login=>login,:key=>key}
    end

    def list
      response = api_get("schema", {:cmd => 'indexlist'})
      response.css('index').map{|i|i.attributes['name'].value}
    end

    def create(template = 'WEB_CRAWLER')
      params = {
        'cmd' => 'createindex',
        'index.name' => @name,
        'index.template' => template
        }
        api_get "schema", params
    end

    def delete!
      params = {
        'cmd' => 'deleteindex',
        'index.name' => @name,
        }
      api_get "schema", params
    end

    def set_field(field_params)
      params = {
        'cmd' => 'setfield',
        'use' => @name,
        'field.default' => field_params['default'] ? 'yes' : 'no',
        'field.unique' => field_params['unique'] ? 'yes' : 'no',
        'field.name' => field_params['name'],
        'field.analyzer' => field_params['analyzer'],
        'field.stored' => field_params['stored'] ? 'yes' : 'no',
        'field.indexed' => field_params['indexed'] ? 'yes' : 'no' ,
        'field.termVector' => field_params['term_vector']
      }
      api_get "schema", params
    end

    def delete_field(name = nil)
      params = {
        'cmd' => 'deletefield',
        'use' => @name,
        'field.name' => name,
      }
      api_get "schema", params
    end

    # Delete the document matching the given primary key
    def delete_document_by_key(key = nil)
      params = {
        'use' => @name,
        'uniq' => key
      }
      api_get "delete", params
    end

    # Delete the document matching the give search query
    def delete_documents_by_query(query = nil)
      params = {
        'use' => @name,
        'q' => query
      }
      api_get "delete", params
    end

    def add_document(doc)
      if doc.is_a?(Array) then
        @documents = doc
      else
        @documents << doc
      end
    end

    def empty_documents
      @documents = []
    end
    
    def index!
      params = {
        'use' => @name
      }
      response = api_post "update", self.to_xml, params
      xml = check_response_xml response
    end
    

    def search(query,  params = nil)
      query_string = flatten_params({:query=>query}.merge(params)).map{|k,v|"#{k}=#{v}"}.join "&" 
      api_get "select?use=#{URI::encode(@name)}&#{query_string}"
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

    def api_get (method, params={})
      params.merge!(@credentials) unless method.start_with? "select" #FIXME grbbl 
      check_response_xml RestClient.get("#{@host}/#{method}", {:params => params})
    end

    def api_post (method, body, params={})
     check_response_xml RestClient.post("#{@host}/#{method}", self.to_xml, {:accept => :xml, :content_type => :xml, :params => params.merge(@credentials)})
    end
    
    def flatten_params(params)
      params_ary=[]
      params.each do |k,v| 
        if v.kind_of?(Array)
          v.each do |vv| 
            params_ary << [k,vv]
          end
        else
          params_ary << [k,v]        
        end
      end
      params_ary
    end


    def check_response_xml(response)
      xml = Nokogiri::XML(response)

      if xml.nil?
        raise Oss::ApiException.new "Failed to parse response as XML\n#{response}"
      end

      status = xml.at_xpath('/response/entry[@key=\'Status\']')

      if status.nil? #FIXME Not all api calls return status
        status = "OK" 
      else
        status = status.text        
      end

      if status != "OK"
        exception = xml.at_xpath('/response/entry[@key=\'Exception\']/text()') || response
        raise Oss::ApiException.new "API Request failed\nStatus: #{status}\n#{exception}"
      end
      return xml
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



  class ApiException < StandardError
    attr_reader :reason
    
    def initialize(reason)
       @reason = reason
    end
    
  end
end

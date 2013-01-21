require 'nokogiri'
require 'rest_client'

class OssIndex
  attr_accessor :documents, :name

  def initialize(name, host = "http://localhost:8080")
    @name = name
    @documents = []
    @host ||= host
  end
  
  def list
    Nokogiri::XML(RestClient.get "#{@host}/schema?cmd=indexlist")
  end
  
  def create!(*template)
    template ||= @default_template
    RestClient.get "#{@host}/schema?cmd=createindex&index.name=#{@name}&index.template=#{@default_template}"
  end
  
  def delete!
    RestClient.get "#{@host}/schema?cmd=deleteindex&index.name=#{@name}&index.delete.name=#{@name}"
  end
  
  def add_document(doc)
    if doc.is_a?(Array) then 
      @documents = doc
    else
      @documents << doc
    end
  end

  def index!
    RestClient.post "#{@host}/update?use=#{@name}", self.to_xml, {:accept => :xml, :content_type => :xml}
  end
  
  def search(term, lang="en")
    RestClient.get "#{@host}/select?use=#{@name}&lang=#{lang}&query=#{URI::encode(term)}&qt=test2"
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
  attr_accessor :lang, :fields, :id
  def initialize(lang ="en", id)
    @lang = lang
    @fields = {}
    self.add_field("id", id)
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
require 'net-http-spy'
require 'open-uri'
require 'net/http'
require 'nokogiri'

class OssIndex
  attr_accessor :documents, :name

  def initialize(name, server = "http://localhost:8080")
    @name = name
    @documents = []
    @url = URI(server)
    @http = Net::HTTP.new(@url.host, @url.port)

  end
  
  def add_document(doc)
    if doc.is_a?(Array) then 
      @documents = doc
    else
      @documents << doc
    end
  end

  def index!
    request = Net::HTTP::Post.new("/update?use=#{@name}")
    request.body = self.to_xml
    request["Content-Type"] = "application/xml"
    response = @http.request(request)
  end
  
  def search(term, lang="en")
    request = Net::HTTP::Get.new("/select?use=#{@name}&lang=#{lang}&query=#{URI::encode(term)}&qt=test2")
    response = @http.request(request)
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
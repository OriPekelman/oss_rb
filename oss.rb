require 'net/http'
require 'nokogiri'
require 'pry'
#<?xml version="1.0" encoding="UTF-8"?>
#<index>
#  <document lang="en">
#    <field name="id"><value>1</value></field>
#    <field name="title"><value>Open Search Server</value></field>
#    <field name="url"><value>http://www.open-search-server.com</value></field>
#    <field name="user">
#      <value>emmanuel_keller</value>
#      <value>philcube</value>
#    </field>
#  </document>
#  <document lang="en">
#    <field name="id"><value>2</value></field>
#    <field name="title"><value>SaaS services | OpenSearchServer</value></field>
#    <field name="url"><value>http://www.open-search-server.com/services/saas_services</value></field>
#    <field name="user">
#      <value>emmanuel_keller</value>
#    </field>
#  </document>
#</index>

class OssIndex
  attr_accessor :documents, :name

  def initialize(name, server = "http://localhost:8080")
    @name = name
    @server= server
    @documents = []

  end
  
  def add_document(doc)
    @documents << doc
  end

  def index!
    uri = URI("#{@server}/update/?use={@name}")
    res = Net::HTTP.post_form(uri,self.to_xml)
    puts res
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
  def initialize(lang ="en")
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

i = OssIndex.new("test")
d = Document.new("en")
d.add_field("user", "john")
d.add_field("user", "jane")
i.add_document(d)
i.add_document(d)
binding.pry
puts i.to_xml

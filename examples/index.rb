require_relative '../oss'
require 'securerandom'
require 'pry'
index = Oss::Index.new("test2")

index.delete!
index.create!
puts index.list

(1..15).each do |i|
  id = SecureRandom.uuid
  doc = Oss::Document.new("en", i)  
  doc.add_field("user", "jane#{i}")
  doc.add_field("user", "john#{i}")
  doc.add_field("url", "http://myserver.com/#{id}")
  index.add_document(doc)
end

index.index!
puts index.search("http*")
require_relative '../lib/oss_rb'
require 'securerandom'
index = Oss::Index.new("test_oss_rb")
index.delete!
indexes = index.create('EMPTY_INDEX')
puts index.list

(1..15).each do |i|
  id = SecureRandom.uuid
  doc = Oss::Document.new 
  doc.add_field("user", "jane#{i}")
  doc.add_field("user", "john#{i}")
  doc.add_field("url", "http://myserver.com/#{id}")
  index.add_document(doc)
end

index.index!
puts index.search("http*")
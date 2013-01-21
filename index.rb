require_relative 'oss'
require 'pry'

index = OssIndex.new("test2")

index.delete!
index.create!
binding.pry
puts index.list

(1..15).each do |i|
  doc = Document.new("en", 1)  
  doc.add_field("user", "jane#{i}")
  doc.add_field("user", "john#{i}")
  index.add_document(doc)
end

puts index.index!.body
puts index.search("j*").body

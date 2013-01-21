require_relative 'oss'
index = OssIndex.new("test2")

(1..15).each do |i|
  doc = Document.new("en", 1)  
  doc.add_field("user", "jane#{i}")
  doc.add_field("user", "john#{i}")
  index.add_document(doc)
end

puts index.index!.body
puts index.search("j*").body

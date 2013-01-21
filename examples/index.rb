require_relative '../oss'

index = Oss::Index.new("test2")

index.delete!
index.create!
puts index.list
binding.pry

(1..15).each do |i|
  doc = Oss::Document.new("en", 1)  
  doc.add_field("user", "jane#{i}")
  doc.add_field("user", "john#{i}")
  doc.add_field("url", "john#{i}")
  index.add_document(doc)
end

index.index!
puts index.search("j*")

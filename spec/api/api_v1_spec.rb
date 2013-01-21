require_relative "../spec_helper"
require "yaml"

describe OssIndex do
  before(:all) do
    @index = OssIndex.new("test2")
  end
  
  describe '#OssIndex(name)' do
    it "should not work with no index name" do
      # OssIndex.new().should raise_error  
    end
  end
  
  describe '#OssIndex' do
    it "fetches the OssIndex client object" do
      @index.should be_an_instance_of OssIndex
    end
  end
  
  describe '#create index' do
    it "create index" do
      indexes = @index.create!
      @index.list.length.should > 0 
    end
  end


end


require_relative "../spec_helper"
require "yaml"

describe Oss::Index do
  before(:all) do
    @name = "test2"
    @index = Oss::Index.new(@name)
  end
  
  describe '#OssIndex(name)' do
    it "should not work with no index name" do
      # Oss::Index.new().should raise_error  
    end
  end
  
  describe '#OssIndex' do
    it "fetches the OssIndex client object" do
      @index.should be_an_instance_of Oss::Index
    end
  end
  
  describe '#create index' do
    it "create index" do
      indexes = @index.create!
      @index.list[@name].should_not_be_nil
    end
  end


end


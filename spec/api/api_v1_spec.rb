require 'pry'

require_relative "../spec_helper"
require "yaml"

describe Oss::Index do
  before(:all) do
    @index_name = "test_oss_rb"
    @index = Oss::Index.new(@index_name)
  end

  describe '#OssIndex(name)' do
    it "should not work with no index name" do
      expect { Oss::Index.new() }.to raise_error
    end
  end

  describe '#OssIndex' do
    it "fetches the OssIndex client object" do
      @index.should be_an_instance_of(Oss::Index)
    end
  end

  describe '#delete index' do
    it "delete index" do
      indexes = @index.delete!
      @index.list.include? @index_name.should == @index_name
    end
  end

  describe '#create index' do
    it "create index" do
      indexes = @index.create('EMPTY_INDEX')
      @index.list.include? @index_name.should == @index_name
    end
  end

  describe '#set fields' do
    it 'set fields' do
      @index.set_field(false, true, 'id', nil, true, true, nil)
      @index.set_field(true, false, 'user', 'StandardAnalyzer', true, true, nil)
      #FIXME no test here... but this is because there seems to be not API method to get the fields
    end
  end

  describe '#index docs' do
    it "create index, set fields, index docs" do
      (1..15).each do |i|
        doc = Oss::Document.new("en")
        doc.add_field('id', "#{i}")
        doc.add_field('user', "john#{i}")
        @index.add_document(doc)
      end
      @index.index!
      params = {
        'start' => 0,
        'rows' => 10,
        'returned_field' => ['id', 'user']
      }
      xml = @index.search('j*', params);
      docs = xml.css('result doc')
      puts docs
      docs.length.should == 10
    end
  end

  describe '#delete fields' do
    it 'set fields, delete fields' do
      @index.delete_field('id')
      @index.delete_field('user')
      #FIXME no test here...
    end
  end

  describe '#delete index' do
    it 'create index, delete index' do
      @index.delete!
      #FIXME no test here...
    end
  end

end
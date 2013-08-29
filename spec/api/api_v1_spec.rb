require_relative "../spec_helper"

describe Oss::Index do
  before(:all) do
    @index_name = "test_oss_rb"
    @index = Oss::Index.new(@index_name, ENV['OSS_RB_URL'], ENV['OSS_RB_LOGIN'], ENV['OSS_RB_KEY'])
    @index.delete!
  end

  describe '#OssIndex(name)' do
    it "should not work with no index name" do
      expect { Oss::Index.new() }.to raise_error
    end
  end

  describe '#Non existing methods' do
    it "should not work" do
      expect {@index.send(:api_get,"plop")}.to raise_error
    end
  end

  describe '#OssIndex' do
    it "fetches the OssIndex client object" do
      @index.should be_an_instance_of(Oss::Index)
    end
  end

  describe '#delete index' do
    it "delete index" do
      index = Oss::Index.new("DELETE_ME", ENV['OSS_RB_URL'], ENV['OSS_RB_LOGIN'], ENV['OSS_RB_KEY'])
      index.create('EMPTY_INDEX')
      index.list.should include "DELETE_ME"
      index.delete!
      index.list.should_not include "DELETE_ME"
    end
  end

  describe '#create index' do
    it "create index" do
      @index.create('WEB_CRAWLER') unless @index.list.include? @index_name
      @index.list.should include @index_name
    end
  end

  describe '#set fields' do
    it 'set fields' do
      params = {
        'name' => 'id',
        'stored' => 'YES',
        'indexed' => 'YES'
      }
      @index.set_field(params)
      params = {
        'name' => 'user',
        'analyzer' => 'StandardAnalyzer',
        'stored' => 'YES',
        'indexed' => 'YES'
      }
      @index.set_field(params)
      @index.set_field_default_unique('user', 'id')
    end
  end

  describe '#index docs' do
    it "create index, set fields, index docs" do
      @index.set_field( {
        'name' => 'user',
        'analyzer' => 'StandardAnalyzer',
        'stored' => 'YES',
        'indexed' => 'YES'
      })
      @index.set_field( {
        'name' => 'id',
        'stored' => 'YES',
        'indexed' => 'YES'
      })
      @index.set_field_default_unique('user', 'id')

      (1..15).each do |i|
        doc = Oss::Document.new()
        doc.fields << Oss::Field.new('id', "#{i}")
        doc.fields << Oss::Field.new('user', "john#{i}")
        @index.documents << doc
      end

      @index.index!
      params = {
        'query' => 'user:j*',
        'start' => 0,
        'rows' => 10,
        "returnedFields" => ['id', 'user']
      }
      result= @index.search_pattern(params);
      result['numFound'].should == 15
      result['documents'].length.should == 10

      @index.search_store_template_pattern('patternsearch', params);
      result = @index.search_template_pattern('patternsearch', params);
      result['numFound'].should == 15
      result['documents'].length.should == 10

      @index.search_template_delete('search');
    end
  end

  describe '#delete fields' do
    it 'set fields, delete fields' do
      @index.delete_field('host')
      @index.delete_field('subhost')
    end
  end

  describe '#delete document by value' do
    it 'index docs, delete document by value' do
      @index.delete_document_by_value('id', 1, 2, 3)
    end

    describe '#delete document by query' do
      it 'index docs, delete document by query' do
        @index.delete_document_by_query('user:john4')
        @index.delete_document_by_query('user:john5')
      end
    end
  end

end
require 'spec-helper'

describe CommonDomain::ReadModel::SqlReadModel do
  include SqlConnectionHelper
  module ReadModel
    include CommonDomain::ReadModel
  end
  let(:schema) { mock(:schema) }
  let(:described_class) { 
    klass = Class.new(ReadModel::SqlReadModel) 
    klass.stub(:name) { "CommonDomain::ReadModel::SqlReadModel::SpecReadModel" }
    klass
  }
  
  let(:connection) {
    sqlite_memory_connection "common-domain::sql-read-model-spec::orm"
  }
  subject { described_class.new connection, ensure_rebuilt: false }
  
  describe "initialization" do
    it "should prepare statements" do
      mock_schema = mock(:schema)
      described_class.send(:define_method, :schema) { mock_schema }
      statements_prepared = false
      described_class.send(:define_method, :prepare_statements) {|s| 
        statements_prepared = true
        s.should == mock_schema
      }
      described_class.new connection
      statements_prepared.should be_true
    end
  end
  
  describe "setup" do
    it "should setup schema" do
      subject.stub(:schema) { schema }
      schema.should_receive(:setup)
      subject.setup
    end
  end
  
  describe "purge!" do
    before(:each) do
      subject.should_receive(:schema) { schema }.any_number_of_times
    end
    
    it "cleanup and setup schema" do
      schema.should_receive(:cleanup)
      schema.should_receive(:setup)
      subject.purge!
    end
  end
  
  describe "setup_schema" do
    it "should assign identifier as read model full name" do
      described_class.setup_schema {}
      subject.schema.options[:identifier].should eql "CommonDomain::ReadModel::SqlReadModel::SpecReadModel"
    end
    
    it "should create instance method with passed block" do
      expect { |b| 
        described_class.setup_schema(&b)
        subject.schema.setup
      }.to yield_with_args(subject.schema)
    end
  end
  
  describe "prepare_statements" do
    before(:each) do
      described_class.setup_schema {}
    end
    it "should create instance method that with passed block" do
      expect { |b| 
        described_class.prepare_statements(&b)
        subject.send(:prepare_statements, subject.schema)
      }.to yield_with_args(subject.schema)
    end
  end
  
  describe "rebuild_required?" do
    before(:each) do
      subject.should_receive(:schema).and_return(schema)
    end
    
    it "should return true if schema needs to be rebuilt" do
      schema.should_receive(:rebuild_required?).and_return(true)
      subject.rebuild_required?.should be_true
    end
  end
end

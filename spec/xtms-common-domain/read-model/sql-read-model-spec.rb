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
  
  describe "setup" do
    before(:each) do
      schema.stub(:meta_store_initialized?) { false }
      subject.stub(:schema) { schema }
    end
    it "should setup schema" do
      schema.should_receive(:setup)
      subject.setup
    end
    
    it "should prepare statements" do
      schema.stub(:setup)
      subject.should_receive(:prepare_statements).with(schema)
      subject.setup
    end
    
    it "should fail if schema meta_store_initialized? and actual_schema_version is not zero" do
      schema.should_receive(:meta_store_initialized?) { true }
      schema.should_receive(:actual_schema_version) { 10 }
      lambda { subject.setup }.should raise_error(ReadModel::SqlReadModel::InvalidStateError)
    end
  end
  
  describe "cleanup!" do
    before(:each) do
      subject.should_receive(:schema) { schema }.any_number_of_times
    end
    
    it "cleanup schema" do
      schema.should_receive(:cleanup)
      subject.cleanup!
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
        subject.send(:setup_schema, subject.schema)
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
  
  describe "setup_required?" do
    before(:each) do
      subject.should_receive(:schema).and_return(schema)
    end
    
    it "should return true if schema needs setup" do
      schema.should_receive(:setup_required?).and_return(true)
      subject.setup_required?.should be_true
    end
  end
end

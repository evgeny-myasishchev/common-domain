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
    klass.setup_schema(:version => 1) {|schema|}
    klass
  }
  
  let(:connection) {
    sqlite_memory_connection "common-domain::sql-read-model-spec::orm"
  }
  subject { described_class.new connection, ensure_rebuilt: false }
  
  describe "initialize" do
    let(:registry) { mock(:registry) }
    
    before(:each) do
      ReadModel::SqlReadModel::DatasetsRegistry.should_receive(:new).with(connection).and_return(registry)
    end
    
    it "should prepare_statements" do
      described_class.class_eval do
        attr_reader :prepare_statements_registry
        def prepare_statements(registry)
          @prepare_statements_registry = registry
        end
      end
      subject.prepare_statements_registry.should be registry
    end
  end
  
  describe "setup" do
    before(:each) do
      subject.stub(:schema) { schema }
    end
    it "should setup schema" do
      schema.should_receive(:actual_schema_version) { 0 }
      schema.should_receive(:setup)
      subject.setup
    end
    
    it "should fail if actual_schema_version is not zero" do
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
    it "should define instance method schema that initializes the schema" do
      schema = nil
      expect {|b| 
        described_class.setup_schema version: 100, &b
        subject = described_class.new connection, ensure_rebuilt: false
        schema = subject.schema
      }.to yield_with_args(lambda { |arg| arg.should be schema })
    end
    
    it "should initialize the schema in scope of read model" do
      scope = nil
      described_class.setup_schema version: 100 do |s|
        scope = self
      end
      subject = described_class.new connection, ensure_rebuilt: false
      scope.should eql subject
    end
    
    it "should assign identifier as read model full name" do
      described_class.setup_schema { |schema| }
      subject.schema.options[:identifier].should eql "CommonDomain::ReadModel::SqlReadModel::SpecReadModel"
    end
  end
  
  describe "prepare_statements" do
    it "should create instance method with passed block" do
      registry = mock(:registry)
      ReadModel::SqlReadModel::DatasetsRegistry.stub(:new) { registry }
      expect { |b| 
        described_class.prepare_statements(&b)
        described_class.new connection
      }.to yield_with_args(registry)
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

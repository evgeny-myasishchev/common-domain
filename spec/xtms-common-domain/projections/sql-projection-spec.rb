require 'spec-helper'

describe CommonDomain::Projections::Sql do
  include SqlConnectionHelper
  module Projection
    include CommonDomain::Projections
  end
  let(:schema) { double(:schema) }
  let(:described_class) { 
    klass = Class.new(Projection::Sql)
    allow(klass).to receive(:name) { "CommonDomain::Projections::Sql::SpecProjection" }
    klass.setup_schema(:version => 1) {|schema|}
    klass
  }
  
  let(:connection) {
    open_sequel_connection "common-domain::sql-projection-spec::orm"
  }
  subject { described_class.new connection, ensure_rebuilt: false }
  
  describe "initialize" do
    let(:registry) { double(:registry) }
    
    before(:each) do
      expect(Projection::Sql::DatasetsRegistry).to receive(:new).with(connection).and_return(registry)
    end
    
    it "should prepare_statements" do
      described_class.class_eval do
        attr_reader :prepare_statements_registry
        def prepare_statements(registry)
          @prepare_statements_registry = registry
        end
      end
      expect(subject.prepare_statements_registry).to be registry
    end
  end
  
  describe "setup" do
    before(:each) do
      allow(subject).to receive(:schema) { schema }
    end
    it "should setup schema" do
      expect(schema).to receive(:actual_schema_version) { 0 }
      expect(schema).to receive(:setup)
      subject.setup
    end
    
    it "should fail if actual_schema_version is not zero" do
      expect(schema).to receive(:actual_schema_version) { 10 }
      expect(lambda { subject.setup }).to raise_error(Projection::Sql::InvalidStateError)
    end
  end
  
  describe "cleanup!" do
    before(:each) do
      allow(subject).to receive(:schema) { schema }
    end
    
    it "cleanup schema" do
      expect(schema).to receive(:cleanup)
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
      }.to yield_with_args(lambda { |arg| expect(arg).to be schema })
    end
    
    it "should initialize the schema in scope of projection" do
      scope = nil
      described_class.setup_schema version: 100 do |s|
        scope = self
      end
      subject = described_class.new connection, ensure_rebuilt: false
      expect(scope).to eql subject
    end
    
    it "should assign identifier as projection full name" do
      described_class.setup_schema { |schema| }
      expect(subject.schema.options[:identifier]).to eql "CommonDomain::Projections::Sql::SpecProjection"
    end
  end
  
  describe "prepare_statements" do
    it "should create instance method with passed block" do
      registry = double(:registry)
      allow(Projection::Sql::DatasetsRegistry).to receive(:new) { registry }
      expect { |b| 
        described_class.prepare_statements(&b)
        described_class.new connection
      }.to yield_with_args(registry)
    end
  end
  
  describe "rebuild_required?" do
    before(:each) do
      expect(subject).to receive(:schema).and_return(schema)
    end
    
    it "should return true if schema needs to be rebuilt" do
      expect(schema).to receive(:rebuild_required?).and_return(true)
      expect(subject.rebuild_required?).to be_truthy
    end
  end
  
  describe "setup_required?" do
    before(:each) do
      expect(subject).to receive(:schema).and_return(schema)
    end
    
    it "should return true if schema needs setup" do
      expect(schema).to receive(:setup_required?).and_return(true)
      expect(subject.setup_required?).to be_truthy
    end
  end
end

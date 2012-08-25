require 'spec-helper'

describe CommonDomain::ReadModel::SqlReadModel do
  module ReadModel
    include CommonDomain::ReadModel
  end
  
  let(:described_class) { Class.new(ReadModel::SqlReadModel) }
  let(:connection) { 
    con = Sequel.connect adapter: "sqlite", database: ":memory:" 
    con.loggers << CommonDomain::Logger.get("common-domain::sql-read-model-spec::orm")
    con
  }
  subject { described_class.new connection, perform_setup: false }
  
  describe "initialization" do
    it "should initialize schema by default" do
      subject = described_class.new connection, perform_setup: true
      subject.ensure_initialized!
    end
    
    it "should not initialize schema if configured" do
      lambda { subject.ensure_initialized! }.should raise_error(ReadModel::SqlReadModel::SchemaNotInitialized)
    end
  end
  
  describe "setup" do
    it "should setup schema and prepare_statements" do
      subject.should_receive(:setup_schema).with(subject.schema)
      subject.should_receive(:prepare_statements).with(subject.schema)
      subject.setup
    end
  end
  
  describe "purge!" do
    it "should drop all tables and setup_schema" do
      subject.setup
      subject.schema.should_receive(:table_names).and_return([:table1, :table2, :table3])
      subject.connection.should_receive(:drop_table).with(:table1)
      subject.connection.should_receive(:drop_table).with(:table2)
      subject.connection.should_receive(:drop_table).with(:table3)
      subject.should_receive(:setup_schema).with(subject.schema)
      subject.purge!
    end
  end
  
  describe "setup_schema" do
    it "should create instance method with passed block" do
      expect { |b| 
        described_class.setup_schema(&b)
        subject.send(:setup_schema, subject.schema)
      }.to yield_with_args(subject.schema)
    end
    
    it "should define " do
      
    end
  end
  
  describe "prepare_statements" do
    it "should create instance method that with passed block" do
      expect { |b| 
        described_class.prepare_statements(&b)
        subject.send(:prepare_statements, subject.schema)
      }.to yield_with_args(subject.schema)
    end
  end
  
  describe "rebuild_required?" do
    before(:each) do
      described_class.class_eval do
        setup_schema do |schema|
          schema.table :accounts, :accounts do
            String :id, :primary_key=>true, :size => 50, :null=>false
            String :name, :size => 50, :null=>false
            Boolean :is_active, :null=>false
          end
          schema.table :roles, :roles do
            String :id, :primary_key=>true, :size => 50, :null=>false
            String :name, :size => 50, :null=>false
          end
        end
      end
    end
    
    it "should be false if schema is the most actual version" do
      subject.setup
      subject.rebuild_required?.should be_true
    end
    
    it "should be true if schema has not been initialized" do
      subject.rebuild_required?.should be_false
    end
    
    it "should be true if actual schema is older than the one that is required by read model" do
      
    end
  end
end

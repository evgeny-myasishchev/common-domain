require 'spec-helper'

describe CommonDomain::ReadModel::SqlReadModel do
  module ReadModel
    include CommonDomain::ReadModel
  end
  class SubjectClass < ReadModel::SqlReadModel
  end
  
  let(:connection) { Sequel.connect adapter: "sqlite", database: ":memory:" }
  subject { SubjectClass.new connection, perform_setup: false }
  
  describe "initialization" do
    it "should initialize schema by default" do
      subject = SubjectClass.new connection, perform_setup: true
      subject.ensure_initialized!
    end
    
    it "should not initialize schema if configured" do
      lambda { subject.ensure_initialized! }.should raise_error(ReadModel::SqlReadModel::SchemaNotInitialized)
    end
  end
  
  describe "setup" do
    it "should setup schema and prepare_statements" do
      schema_setup           = mock(:schema_setup)
      statements_preparation = mock(:statements_preparation)
      schema_setup.should_receive(:call).with(subject.schema)
      statements_preparation.should_receive(:call).with(subject.schema)
      SubjectClass.should_receive(:schema_setup).any_number_of_times.and_return(schema_setup)
      SubjectClass.should_receive(:statements_preparation).twice.and_return(statements_preparation)
      subject.setup
    end
    
    it "should do nothing if schema_setup and statements_preparation are nil" do
      SubjectClass.should_receive(:schema_setup).and_return(nil)
      SubjectClass.should_receive(:statements_preparation).and_return(nil)
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
      schema_setup = mock(:schema_setup)
      schema_setup.should_receive(:call).with(subject.schema)
      SubjectClass.should_receive(:schema_setup).any_number_of_times.and_return(schema_setup)
      subject.purge!
    end
  end
end

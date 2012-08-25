require 'spec-helper'

describe CommonDomain::ReadModel::SqlReadModel::Schema do
  let(:connection) {
    Sequel.connect adapter: "sqlite", database: ":memory:"
  }
  
  subject {
    described_class.new connection, identifier: "schema-1" do |schema|
      
    end
  }
  
  describe "initialize" do
    it "should raise error if identifier is no provided" do
      lambda { described_class.new connection, {} }.should raise_error(RuntimeError)
    end
  end
  
  describe "setup_required?" do
    it "should return true the schema has never been initialized"
    
    it "should return true if the schema is outdated"
    
    it "should return false if actual schema is the most recent version"
  end
  
  describe "setup" do
    it "should call block passed to initializer" do
      subject = nil
      expect {|b| 
        subject = described_class.new connection, {identifier: "schema-1"}, &b
        subject.setup
      }.to yield_with_args(subject)
    end
    it "should create special table to record schema versions"
    it "should insert new schema version"
    it "should update schema version"
  end
  
  describe "table" do
    before(:each) do
      subject.table(:table1, :new_table_name) do
        String :id, :primary_key=>true, :size => 50, :null=>false
      end
    end
    
    it "should remember all schema tables" do
      subject.table(:table2, :new_table_name2) do
        String :id, :primary_key=>true, :size => 50, :null=>false
      end    
      subject.table_names.should have(2).items
      subject.table_names.should include(:new_table_name)
      subject.table_names.should include(:new_table_name2)
    end
    
    it "should create new table" do
      connection.tables.should include :new_table_name
      columns = connection.schema(:new_table_name)
      columns.should have(1).items
    end
    
    it "should not respond to unknown accessors" do
      subject.should_not respond_to(:unknown_table)
      lambda { subject.unknown_table }.should raise_error(NoMethodError)      
    end
    
    it "should have dataset accessor" do
      subject.should respond_to(:table1)
      subject.table1.should be_instance_of(Sequel::SQLite::Dataset)
      subject.table1.first_source.should eql :new_table_name
    end
    
    it "should do nothing if the table already exist" do
      expect { |b| subject.table(:table1, :new_table_name, &b) }.not_to yield_control
    end
  end
end

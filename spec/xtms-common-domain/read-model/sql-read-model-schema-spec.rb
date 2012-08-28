require 'spec-helper'

describe CommonDomain::ReadModel::SqlReadModel::Schema do
  include SqlConnectionHelper
  include SchemaHelper
  let(:connection) { sqlite_memory_connection }
  let(:info_table_name) { described_class::MetaStoreTableName }
  subject {
    described_class.new connection, identifier: "schema-1", version: 20 do |schema|
    end
  }
  
  describe "initialize" do
    it "should raise error if identifier is no provided" do
      lambda { described_class.new connection, {} }.should raise_error(RuntimeError)
    end
    
    it "should have default version as one" do
      subject = described_class.new(connection, {identifier: 'some-identifier'})
      subject.options[:version].should eql 1
    end
  end
  
  describe "meta_store_initialized?" do
    before(:each) do
      subject.setup
    end
    
    it "should return true if meta store table exists" do
      subject.meta_store_initialized?.should be_true
    end
    
    it "should return false if there is no meta store table" do
      connection.drop_table info_table_name
      subject.meta_store_initialized?.should be_false
    end
  end
  
  describe "actual_schema_version" do
    before(:each) do
      subject.setup
    end
    it "should fail if meta store has not been initialized" do
      subject.should_receive(:meta_store_initialized?) { false }
      lambda { subject.actual_schema_version }.should raise_error(RuntimeError)
    end
    
    it "should return zero if there is no corresponding identifier in the meta store" do
      connection[info_table_name].delete
      subject.actual_schema_version.should eql 0
    end
    
    it "should return value for the corresponding identifier" do
      connection[info_table_name].update(:'schema-version' => 449)
      subject.actual_schema_version.should eql 449
    end
  end
  
  describe "setup_required?" do
    before(:each) do
      subject.setup
    end
    
    it "should return true if there is no schema info table" do
      connection.drop_table info_table_name
      subject.setup_required?.should be_true
    end
    
    it "should return true the schema has never been initialized" do
      connection[info_table_name].delete
      subject.setup_required?.should be_true
    end
    
    it "should return false if schema has been already initialized" do
      subject.setup
      subject.setup_required?.should be_false
    end
    
    it "should return false even if schema version is different" do
      subject.setup
      dataset = connection[info_table_name]
      dataset.update(:'schema-version' => 19)
      subject.setup_required?.should be_false
    end
  end
  
  describe "rebuild_required?" do
    before(:each) do
      subject.setup
    end
    
    it "should return true if there is no schema info table" do
      connection.drop_table info_table_name
      subject.rebuild_required?.should be_true
    end
    
    it "should return true the schema has never been initialized" do
      connection[info_table_name].delete
      subject.rebuild_required?.should be_true
    end
    
    it "should return true if the schema is outdated" do
      subject.setup
      dataset = connection[info_table_name]
      dataset.update(:'schema-version' => 19)
      subject.rebuild_required?.should be_true
    end
    
    it "should return false if actual schema is the most recent version" do
      subject.setup
      subject.rebuild_required?.should be_false
    end
  end
  
  describe "setup" do
    before(:each) do
      subject.setup
    end
    
    it "should call block passed to initializer" do
      subject = nil
      expect {|b| 
        subject = described_class.new connection, {identifier: "schema-1"}, &b
        subject.setup
      }.to yield_with_args(subject)
    end
    
    it "should create special table to record schema versions" do
      connection.should have_table info_table_name
      check_column(connection, info_table_name, :identifier) do |column|
        column[:allow_null].should be_false
        column[:primary_key].should be_true
        column[:type].should be :string
        column[:db_type].should eql "varchar(200)"
      end
      
      check_column(connection, info_table_name, :'schema-version') do |column|
        column[:allow_null].should be_false
        column[:type].should be :integer
      end      
    end
    
    it "should insert new schema version for given identifier" do
      dataset = connection[info_table_name]
      dataset.should have(1).items
      rec = dataset.first
      rec[:identifier].should eql "schema-1"
      rec[:'schema-version'].should eql 20
    end
    
    it "should update schema version" do
      dataset = connection[info_table_name]
      dataset.update :'schema-version' => 10
      subject.setup
      rec = dataset.first
      rec[:identifier].should eql "schema-1"
      rec[:'schema-version'].should eql 20
    end
  end
  
  describe "cleanup" do
    subject {
      schema = described_class.new connection, identifier: "schema-cleanup-spec", version: 20 do |schema|
        schema.table :table_one, :'table-one' do
          Integer :id, :primary_key => true
        end
        schema.table :table_two, :'table-two' do
          Integer :id, :primary_key => true
        end
      end
      schema
    }
    
    before(:each) do
      subject.setup
      connection.create_table :'table-three' do
        Integer :id, :primary_key => true
      end
      subject.cleanup
    end
    
    it "should drop all tables" do
      connection.tables.should include(:'table-three')
      connection.tables.should_not include(:'table-one')
      connection.tables.should_not include(:'table-two')
    end
    
    it "should remove all info from info table" do
      connection[info_table_name].where(:identifier => "schema-cleanup-spec").should be_empty
    end
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

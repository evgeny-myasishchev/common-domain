require 'spec-helper'

describe CommonDomain::Projections::Sql::Schema do
  include SqlConnectionHelper
  include SchemaHelper
  let(:connection) { open_sequel_connection }
  let(:info_table_name) { described_class::MetaStoreTableName }
  subject {
    described_class.new connection, identifier: "schema-1", version: 20 do |schema|
    end
  }
  
  describe "initialize" do
    it "should raise error if identifier is not provided" do
      expect(lambda { described_class.new connection, {} }).to raise_error(RuntimeError)
    end
    
    it "should raise error if version is zero" do
      expect(lambda { described_class.new connection, {identifier: "schema-1", version: 0} }).to raise_error(RuntimeError)
    end
    
    it "should have default version as one" do
      subject = described_class.new(connection, {identifier: 'some-identifier'})
      expect(subject.options[:version]).to eql 1
    end
    
    it "should call block passed to initializer" do
      subject = nil
      expect {|b| 
        subject = described_class.new connection, {identifier: "schema-1"}, &b
      }.to yield_with_args(lambda { |arg| expect(arg).to be subject })
    end
    
    it "should create special table to record schema versions" do
      described_class.new connection, identifier: "schema-1"
      expect(connection).to have_table info_table_name
      check_column(connection, info_table_name, :identifier) do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:primary_key]).to be_truthy
        expect(column[:type]).to be :string
        expect(column[:db_type]).to eql "varchar(200)"
      end
      
      check_column(connection, info_table_name, :'schema-version') do |column|
        expect(column[:allow_null]).to be_falsey
        expect(column[:type]).to be :integer
      end
    end
  end
  
  describe "actual_schema_version" do
    before(:each) do
      subject.setup
    end
    
    it "should return zero if there is no corresponding identifier in the meta store" do
      connection[info_table_name].delete
      expect(subject.actual_schema_version).to eql 0
    end
    
    it "should return value for the corresponding identifier" do
      connection[info_table_name].update(:'schema-version' => 449)
      expect(subject.actual_schema_version).to eql 449
    end
  end
  
  describe "setup_required?" do
    before(:each) do
      subject.setup
    end
    
    it "should return true the schema has never been initialized" do
      connection[info_table_name].delete
      expect(subject.setup_required?).to be_truthy
    end
    
    it "should return false if schema has been already initialized" do
      subject.setup
      expect(subject.setup_required?).to be_falsey
    end
    
    it "should return false even if schema version is different" do
      subject.setup
      dataset = connection[info_table_name]
      dataset.update(:'schema-version' => 19)
      expect(subject.setup_required?).to be_falsey
    end
  end
  
  describe "rebuild_required?" do
    before(:each) do
      subject.setup
    end
    
    it "should return true the schema has never been initialized" do
      connection[info_table_name].delete
      expect(subject.rebuild_required?).to be_truthy
    end
    
    it "should return true if the schema is outdated" do
      subject.setup
      dataset = connection[info_table_name]
      dataset.update(:'schema-version' => 19)
      expect(subject.rebuild_required?).to be_truthy
    end
    
    it "should return false if actual schema is the most recent version" do
      subject.setup
      expect(subject.rebuild_required?).to be_falsey
    end
  end
  
  describe "setup" do
    before(:each) do
      subject.setup
    end
    
    it "should insert new schema version for given identifier" do
      dataset = connection[info_table_name]
      expect(dataset.count).to eql(1)
      rec = dataset.first
      expect(rec[:identifier]).to eql "schema-1"
      expect(rec[:'schema-version']).to eql 20
    end
    
    it "should update schema version" do
      dataset = connection[info_table_name]
      dataset.update :'schema-version' => 10
      subject.setup
      rec = dataset.first
      expect(rec[:identifier]).to eql "schema-1"
      expect(rec[:'schema-version']).to eql 20
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
      connection.drop_table?(:'table-three')
      connection.create_table :'table-three' do
        Integer :id, :primary_key => true
      end
      subject.cleanup
    end
    
    it "should drop all tables" do
      expect(connection.tables).to include(:'table-three')
      expect(connection.tables).not_to include(:'table-one')
      expect(connection.tables).not_to include(:'table-two')
    end
    
    it "should remove all info from info table" do
      expect(connection[info_table_name].where(:identifier => "schema-cleanup-spec")).to be_empty
    end
    
    it "should not fail if there are already no tables" do
      expect(lambda { subject.cleanup }).not_to raise_error
    end
  end
  
  describe "table" do
    before(:each) do
      connection.drop_table? :new_table_name
      subject.table(:table1, :new_table_name) do
        String :id, :primary_key=>true, :size => 50, :null=>false
      end
    end
    
    it "should remember all schema tables" do
      connection.drop_table? :new_table_name2
      subject.table(:table2, :new_table_name2) do
        String :id, :primary_key=>true, :size => 50, :null=>false
      end    
      expect(subject.table_names.length).to eql(2)
      expect(subject.table_names).to include(:new_table_name)
      expect(subject.table_names).to include(:new_table_name2)
    end
    
    it "should not create new table immediatelly" do
      expect(connection.tables).not_to include :new_table_name
    end
    
    it "should create new table on setup" do
      subject.setup
      expect(connection.tables).to include :new_table_name
      columns = connection.schema(:new_table_name)
      expect(columns.length).to eql(1)
    end
    
    it "should do nothing if the table already exist" do
      expect { |b| subject.table(:table1, :new_table_name, &b) }.not_to yield_control
    end
    
    it "should record tables into the registry" do
      expect(subject.datasets_registry).to receive(:table).with(:table1, :new_table_one)
      expect(subject.datasets_registry).to receive(:table).with(:table2, :new_table_two)
      subject.table(:table1, :new_table_one) {}
      subject.table(:table2, :new_table_two) {}
    end
  end
end

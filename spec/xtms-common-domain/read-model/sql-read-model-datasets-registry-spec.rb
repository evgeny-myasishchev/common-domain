require 'spec-helper'

describe CommonDomain::ReadModel::SqlReadModel::DatasetsRegistry do
  include SqlConnectionHelper
  let(:connection) { sqlite_memory_connection }
  subject { described_class.new connection }
  
  describe "table" do
    before(:each) do
      subject.table(:table1, :new_table_name)
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
  end
end
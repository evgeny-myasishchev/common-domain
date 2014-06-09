require 'spec-helper'

describe CommonDomain::Projections::Sql::DatasetsRegistry do
  include SqlConnectionHelper
  let(:connection) { sqlite_memory_connection }
  subject { described_class.new connection }
  
  describe "table" do
    before(:each) do
      subject.table(:table1, :new_table_name)
    end
    
    it "should not respond to unknown accessors" do
      expect(subject).not_to respond_to(:unknown_table)
      expect(lambda { subject.unknown_table }).to raise_error(NoMethodError)      
    end
    
    it "should have dataset accessor" do
      expect(subject).to respond_to(:table1)
      expect(subject.table1).to be_instance_of(Sequel::SQLite::Dataset)
      expect(subject.table1.first_source).to eql :new_table_name
    end
  end
end
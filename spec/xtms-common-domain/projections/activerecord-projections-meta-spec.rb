require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord::ProjectionsMeta do
  include ActiveRecordHelpers
  use_sqlite_activerecord_connection 'ar-projections-spec.sqlite'
  
  before(:each) do
    described_class.ensure_schema!
  end
  
  it "should not create schema twice" do
    described_class.ensure_schema!
  end
  
  it "should be active record" do
    described_class.superclass.should eql ::ActiveRecord::Base
  end
  
  it "should setup schema table to store schema meta" do
    connection = Sequel.connect adapter: "sqlite", database: @db_path.to_s
    connection.should have_table described_class.table_name.to_sym do |table|
      table.should have_column(:id, primary_key: true, allow_null: false)
      table.should have_column(:projection_id, allow_null: false, type: :string)
      table.should have_column(:version, allow_null: false, type: :integer)
    end
  end
  
  describe "setup_required?" do
    it "should be true if there is no corresponding record for the specified projection" do
      described_class.setup_required?('projection-992').should be_false
      described_class.create! projection_id: 'projection-992', version: 0
      described_class.setup_required?('projection-992').should be_true
    end
  end
  
  describe "rebuild_required?" do
    before(:each) do
      described_class.create! projection_id: 'projection-993', version: 10
    end
    
    it "should be true if last recorded version is lowwer" do
      described_class.rebuild_required?('projection-993', 20).should be_true
      described_class.rebuild_required?('projection-993', 10).should be_false
    end
    
    it "should raise error if last known version is higher" do
      lambda { described_class.rebuild_required?('projection-993', 5) }.should raise_error("Downgrade is not supported for projection projection-993. Last known version is 10. Requested projection version was 5.")
    end
  end
end

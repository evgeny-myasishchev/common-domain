require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord::ProjectionsMeta do
  include ActiveRecordHelpers
  use_sqlite_activerecord_connection 'ar-projections-spec.sqlite'
  
  it "should be active record" do
    described_class.superclass.should eql ::ActiveRecord::Base
  end
  
  describe "ensure_schema!" do
    before(:each) do
      described_class.ensure_schema!
    end
    
    it "should setup schema table" do
      connection = Sequel.connect adapter: "sqlite", database: @db_path.to_s
      connection.should have_table described_class.table_name.to_sym do |table|
        table.should have_column(:id, primary_key: true, allow_null: false)
        table.should have_column(:projection_id, allow_null: false, type: :string)
        table.should have_column(:version, allow_null: false, type: :integer)
      end
    end
  end
end

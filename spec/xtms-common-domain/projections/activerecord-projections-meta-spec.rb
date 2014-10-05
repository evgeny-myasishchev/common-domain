require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord::ProjectionsMeta do
  include ActiveRecordHelpers
  include SqlConnectionHelper
  establish_activerecord_connection
  let(:connection) { open_sequel_connection }
  
  before(:each) do
    connection.drop_table? described_class.table_name
    described_class.ensure_schema!
  end
  
  it "should not create schema twice" do
    described_class.ensure_schema!
  end
  
  it "should be active record" do
    expect(described_class.superclass).to eql ::ActiveRecord::Base
  end
  
  it "should setup schema table to store schema meta" do
    expect(connection).to have_table described_class.table_name.to_sym do |table|
      expect(table).to have_column(:id, primary_key: true, allow_null: false)
      expect(table).to have_column(:projection_id, allow_null: false, type: :string)
      expect(table).to have_column(:version, allow_null: false, type: :integer)
    end
  end
  
  describe "setup_required?" do
    it "should be true if there is no corresponding record for the specified projection" do
      expect(described_class.setup_required?('projection-992')).to be_truthy
      described_class.create! projection_id: 'projection-992', version: 0
      expect(described_class.setup_required?('projection-992')).to be_falsey
    end
  end
  
  describe "rebuild_required?" do
    before(:each) do
      described_class.create! projection_id: 'projection-993', version: 10
    end
    
    it "should be false if not recorded" do
      expect(described_class.rebuild_required?('projection-33223322', 1)).to be_falsey
    end
    
    it "should be true if last recorded version is lowwer" do
      expect(described_class.rebuild_required?('projection-993', 20)).to be_truthy
      expect(described_class.rebuild_required?('projection-993', 10)).to be_falsey
    end
    
    it "should raise error if last known version is higher" do
      expect(lambda { described_class.rebuild_required?('projection-993', 5) }).to raise_error("Downgrade is not supported for projection projection-993. Last known version is 10. Requested projection version was 5.")
    end
  end
end

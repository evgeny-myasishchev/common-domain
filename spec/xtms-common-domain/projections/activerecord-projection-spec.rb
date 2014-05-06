require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord do
  require 'active_record'
  
  before(:all) do
    @db_path = @tmp_root.join('ar-projections-spec.sqlite')
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: @db_path
    )
  end
  
  after(:all) do
    ActiveRecord::Base.remove_connection
  end
  
  class TheProjection < ActiveRecord::Base
    include CommonDomain::Projections::ActiveRecord
  end
  
  subject { TheProjection }
  
  it "should be a base projection" do
    TheProjection.should be_a CommonDomain::Projections::Base
  end
  
  describe "projection config" do
    class ProjectionConfigSpec < ActiveRecord::Base
      include CommonDomain::Projections::ActiveRecord
    end
    subject { ProjectionConfigSpec }
    
    it "should have default config" do
      subject.config.should eql version: 0, identifier: 'projection_config_specs'
    end
    
    describe "configured" do
      before(:each) do
        subject.projection version: 100, identifier: 'some-identifier-100'
      end
      
      it "should assign specific values" do
        subject.config.should eql version: 100, identifier: 'some-identifier-100'
      end
    end
  end
  
  describe CommonDomain::Projections::ActiveRecord::ProjectionsMeta do
    let(:described_class) { CommonDomain::Projections::ActiveRecord::ProjectionsMeta }
    # subject { CommonDomain::Projections::ActiveRecord::ProjectionsMeta.new }
    it "should be active record" do
      # puts "@tmp_root: #{tmp_root}"
      # subject.should be_a ::ActiveRecord::Base
    end
  end
end
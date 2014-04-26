require 'spec-helper'

describe CommonDomain::Projections::ActiveRecord do
  require 'active_record'
  
  class TheProjection < ActiveRecord::Base
    include CommonDomain::Projections::ActiveRecord
  end
  
  it "should be a base projection" do
    TheProjection.should be_a CommonDomain::Projections::Base
  end
end
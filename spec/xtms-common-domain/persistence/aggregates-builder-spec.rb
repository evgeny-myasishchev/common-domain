require 'spec-helper'

describe CommonDomain::Persistence::AggregatesBuilder do
  describe "build" do
    it "should return a new instance of the aggregate class initialized with id" do
      class Account < CommonDomain::Aggregate
      end
      account = subject.build Account, "account-1"
      account.should be_instance_of(Account)
      account.aggregate_id.should eql "account-1"
    end
  end
end
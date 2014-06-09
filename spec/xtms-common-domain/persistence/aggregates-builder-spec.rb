require 'spec-helper'

describe CommonDomain::Persistence::AggregatesBuilder do
  describe "build" do
    it "should return a new instance of the aggregate class initialized with id" do
      class Account < CommonDomain::Aggregate
      end
      account = subject.build Account, "account-1"
      expect(account).to be_instance_of(Account)
      expect(account.aggregate_id).to eql "account-1"
    end
  end
end
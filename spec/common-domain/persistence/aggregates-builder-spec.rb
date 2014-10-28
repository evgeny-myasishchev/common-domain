require 'spec-helper'

describe CommonDomain::Persistence::AggregatesBuilder do
  describe "build" do
    class Account < CommonDomain::Aggregate
      attr_reader :snapshot
      def apply_snapshot(snapshot)
        @snapshot = snapshot
      end
    end
    
    it "should return a new instance of the aggregate class initialized with id" do
      account = subject.build Account, "account-1"
      expect(account).to be_instance_of(Account)
      expect(account.aggregate_id).to eql "account-1"
    end
    
    it 'should apply_snapshot if provided' do
      snapshot = double(:snapshot)
      account = subject.build Account, "account-1", snapshot: snapshot
      expect(account.snapshot).to be snapshot
    end
  end
end
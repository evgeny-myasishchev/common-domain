require 'spec-helper'

describe CommonDomain::Persistence::Repository::AbstractWork do
  describe "on_committed/notify_on_committed" do
    it "should record and call all registered callbacks" do
      expect { |callback| 
        subject.on_committed &callback
        subject.on_committed &callback
        subject.send(:notify_on_committed)
      }.to yield_successive_args([], [])
    end
  end
end
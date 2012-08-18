require 'spec-helper'

describe CommonDomain::EventBus do
  it "should be a kind of a MessagesRouter" do
    subject.should be_a_kind_of CommonDomain::Infrastructure::MessagesRouter
  end
end
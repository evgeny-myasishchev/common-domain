require 'spec-helper'

describe CommonDomain::Projections::Base do
  it "should be a MessagesHandler" do
    subject.should be_a(CommonDomain::Infrastructure::MessagesHandler)
  end
end

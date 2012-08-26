require 'spec-helper'

describe CommonDomain::ReadModel::Base do
  it "should be a MessagesHandler" do
    subject.should be_a(CommonDomain::Infrastructure::MessagesHandler)
  end
end

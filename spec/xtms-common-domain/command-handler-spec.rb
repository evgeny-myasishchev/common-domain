require 'spec-helper'

describe CommonDomain::CommandHandler do
  it "should be a kind of a MessagesHandler" do
    subject.should be_a_kind_of CommonDomain::Infrastructure::MessagesHandler
  end
end
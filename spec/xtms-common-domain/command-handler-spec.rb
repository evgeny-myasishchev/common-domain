require 'spec-helper'

describe CommonDomain::CommandHandler do
  it "should be a kind of a MessagesHandler" do
    subject.should be_a_kind_of CommonDomain::Infrastructure::MessagesHandler
  end
  
  it "should be possible to define message handlers that will be wrapped into begin_work"
end
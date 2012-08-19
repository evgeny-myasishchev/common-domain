require 'spec-helper'

describe CommonDomain::ReadModel::Base do
  it "should be a MessagesHandler" do
    subject.should be_a(CommonDomain::Infrastructure::MessagesHandler)
  end
  
  it "should ensure initialized when handling messages" do
    subject.should_receive(:ensure_initialized!)
    lambda {  subject.handle_message("Hello") }.should raise_error(CommonDomain::Infrastructure::MessagesHandler::UnknownHandlerError)
  end
end

require 'spec-helper'

describe CommonDomain::CommandDispatcher do
  it "should be a kind of a MessagesRouter" do
    subject.should be_a_kind_of CommonDomain::Infrastructure::MessagesRouter
  end
  
  describe "dispatch" do
    it "should route command" do
      command = mock(:command)
      subject.should_receive(:route).with(command, ensure_single_handler: true, fail_if_no_handlers: true)
      subject.dispatch(command)
    end
  end
end
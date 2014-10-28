require 'spec-helper'

describe CommonDomain::CommandDispatcher do
  it "should be a kind of a MessagesRouter" do
    expect(subject).to be_a_kind_of CommonDomain::Infrastructure::MessagesRouter
  end
  
  describe "dispatch" do
    it "should route command" do
      command = double(:command)
      expect(subject).to receive(:route).with(command, ensure_single_handler: true, fail_if_no_handlers: true)
      subject.dispatch(command)
    end

    it "should route command with headers" do
      command = double(:command)
      headers = {header1: "header1", header2: "header2"}
      expect(subject).to receive(:route).with(command, ensure_single_handler: true, fail_if_no_handlers: true, headers: headers)
      subject.dispatch(command, headers)
    end
  end
end
require 'spec-helper'

describe CommonDomain::Persistence::Repository do
  describe "begin_work" do
    let(:work) { mock(:work, commit_changes: nil) }
    before(:each) do
      subject.should_receive(:create_work).and_return(work)
    end
    
    it "should create work, yield it and commit_changes" do
      subject.begin_work do |w|
        w.should be work 
        w.should_receive(:commit_changes)
      end
    end
    
    it "should return nil" do
      result = subject.begin_work { |w| }
      result.should be_nil
    end
    
    it "should commit the work with headers if supplied" do
      headers = {header1: 'header-1'}
      subject.begin_work headers do |w|
        w.should_receive(:commit_changes).with(headers)
      end
    end
  end
end
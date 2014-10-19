require 'spec-helper'

describe CommonDomain::Persistence::Repository do
  describe "begin_work" do
    let(:work) { double(:work, commit_changes: nil) }
    before(:each) do
      expect(subject).to receive(:create_work).and_return(work)
    end
    
    it "should create work, yield it and commit_changes" do
      subject.begin_work do |w|
        expect(w).to be work 
        expect(w).to receive(:commit_changes)
      end
    end
    
    it "should return nil" do
      result = subject.begin_work { |w| }
      expect(result).to be_nil
    end
    
    it "should commit the work with headers if supplied" do
      headers = {header1: 'header-1'}
      subject.begin_work headers do |w|
        expect(w).to receive(:commit_changes).with(headers)
      end
    end

    it "should return object returned by the block" do
      result = double(:result)
      expect(subject.begin_work do |w|
        result
      end).to be result
    end
  end
end
require 'spec-helper'

describe CommonDomain::Projections::Base do
  it "should be a MessagesHandler" do
    subject.should be_a(CommonDomain::Infrastructure::MessagesHandler)
  end
  
  describe "self.create_projection" do
    class SomeProjection < described_class
      attr_reader :arg1, :arg2, :arg3
      def initialize(arg1, arg2, arg3)
        @arg1, @arg2, @arg3 = arg1, arg2, arg3
      end
    end
    
    it "should call a constructor with args" do
      subject = SomeProjection.create_projection "arg-1", "arg-2", "arg-3"
      subject.should be_instance_of(SomeProjection)
      subject.arg1.should eql 'arg-1'
      subject.arg2.should eql 'arg-2'
      subject.arg3.should eql 'arg-3'
    end
  end
end

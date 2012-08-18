require 'spec-helper'

describe CommonDomain::Infrastructure::ReadModelsRegistry do
  let(:event_bus) { mock(:event_bus, :register => nil) }
  let(:read_model) { mock(:read_model) }
  let(:subject) { described_class.new event_bus }
  
  describe "register" do
    it "should register read model into event bus" do
      event_bus.should_receive(:register).with(read_model)
      subject.register :read_model, read_model
    end
    
    it "should define reader to access the read-model" do
      subject.register :read_model_one, read_model
      subject.register :read_model_two, read_model
      subject.should respond_to(:read_model_one)
      subject.should respond_to(:read_model_two)
      subject.read_model_one.should be read_model
      subject.read_model_two.should be read_model
    end
    
    it "should fail to register another model with same key" do
      subject.register :read_model_one, read_model
      lambda { subject.register :read_model_one, read_model }.should raise_error(CommonDomain::Infrastructure::ReadModelsRegistry::DuplicateKeyError)
    end
    
    it "should raise NoMethodError for unknown read model" do
      lambda { subject.unknown_read_model }.should raise_error(NoMethodError)
    end
  end
  
  describe "for_each" do
    it "should iterate through each registered read model and yield it" do
      rm1 = mock(:rm1)
      rm2 = mock(:rm2)
      rm3 = mock(:rm3)
      subject.register :rm1, rm1
      subject.register :rm2, rm2
      subject.register :rm3, rm3
      
      expect { |b| 
        subject.for_each &b
      }.to yield_successive_args(rm1, rm2, rm3)
    end
  end
end

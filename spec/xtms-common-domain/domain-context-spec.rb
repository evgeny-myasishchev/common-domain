require 'spec-helper'

describe CommonDomain::DomainContext do
  let(:described_class) {
    Class.new(CommonDomain::DomainContext) do
      def with_read_models(&block)
        bootstrap_read_models &block
      end
    end
  }
  subject { described_class.new }
  let(:rm1) { mock(:read_model_one, :setup => nil) }
  let(:rm2) { mock(:read_model_two, :setup => nil) }
  
  def register_rmx
    subject.with_read_models do |read_models|
      read_models.register :rm1, rm1
      read_models.register :rm2, rm2
    end
  end
  
  describe "rebuild_read_models" do
    it "should rebuild read models with all events" do
      
    end
  end
  
  describe "bootstrap_read_models" do
    it "should setup each read model" do
      rm1.should_receive(:setup)
      rm2.should_receive(:setup)
      register_rmx
    end
  end
end
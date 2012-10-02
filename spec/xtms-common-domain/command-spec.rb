require 'spec-helper'

describe CommonDomain::Command do
  module Commands
    class SampleCommand < CommonDomain::Command
      attr_reader :name, :description
    end
  end
  
  it "should initialize attributes" do
    cmd = Commands::SampleCommand.new "aggregate-1", :name => "name-1", :description => "description-1"
    cmd.aggregate_id.should eql "aggregate-1"
    cmd.name.should eql "name-1"
    cmd.description.should eql "description-1"
  end
  
  it "should have headers hash" do
    cmd = Commands::SampleCommand.new
    cmd.headers.should_not be_nil
    cmd.headers.should be_instance_of(Hash)
  end
  
  describe "from_hash" do
    it "should use class_name param to get command class, instantiate it passing other hash keys as arguments" do
      target = described_class.from_hash(
        class_name: "Commands::SampleCommand", 
        aggregate_id: "aggregate-1",
        name: "name-1",
        description: "description-1")
      target.should be_instance_of(Commands::SampleCommand)
      target.aggregate_id.should eql "aggregate-1"
      target.name.should eql "name-1"
      target.description.should eql "description-1"
    end
    
    it "should fail if no class_name argument present" do
      lambda { described_class.from_hash(aggregate_id: "aggregate-id") }.should raise_error(CommonDomain::CommandClassMissingError)
    end
  end
end
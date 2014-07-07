require 'spec-helper'

describe CommonDomain::Command do
  module Commands
    include CommonDomain::Command::DSL
    
    command :SampleCommand, :name, :description
    command :OtherCommand
  end
  
  it "should initialize attributes" do
    cmd = Commands::SampleCommand.new "aggregate-1", :name => "name-1", :description => "description-1"
    expect(cmd.aggregate_id).to eql "aggregate-1"
    expect(cmd.name).to eql "name-1"
    expect(cmd.description).to eql "description-1"
  end
  
  it "should have headers hash" do
    cmd = Commands::SampleCommand.new
    expect(cmd.headers).not_to be_nil
    expect(cmd.headers).to be_instance_of(Hash)
  end

  it "should initialize headers and attributes" do
    cmd = Commands::SampleCommand.new "aggregate-1", attributes: { name: "name-1", description: "description-1" }, headers: {header1: 'header 1', header2: 'header 2'}
    expect(cmd.aggregate_id).to eql "aggregate-1"
    expect(cmd.name).to eql "name-1"
    expect(cmd.description).to eql "description-1"
    expect(cmd.headers).to eql(header1: 'header 1', header2: 'header 2')
  end
  
  describe "from_hash" do
    it "should use class_name param to get command class, instantiate it passing other hash keys as arguments" do
      target = described_class.from_hash(
        class_name: "Commands::SampleCommand", 
        aggregate_id: "aggregate-1",
        name: "name-1",
        description: "description-1")
      expect(target).to be_instance_of(Commands::SampleCommand)
      expect(target.aggregate_id).to eql "aggregate-1"
      expect(target.name).to eql "name-1"
      expect(target.description).to eql "description-1"
    end
    
    it "should fail if no class_name argument present" do
      expect(lambda { described_class.from_hash(aggregate_id: "aggregate-id") }).to raise_error(CommonDomain::CommandClassMissingError)
    end
    
    it "should not fail if no class_name argument and calling on concrete class" do
      cmd = Commands::SampleCommand.from_hash aggregate_id: 'a-1', name: 'name-1', description: 'description-1'
      expect(cmd).to be_an_instance_of Commands::SampleCommand
      expect(cmd.aggregate_id).to eql 'a-1'
      expect(cmd.name).to eql 'name-1'
      expect(cmd.description).to eql 'description-1'
    end
    
    it "should force the class to be an instance of a concrete class even if class_name is present" do
      cmd = Commands::SampleCommand.from_hash class_name: Commands::OtherCommand.to_s, aggregate_id: 'a-1', name: 'name-1'
      expect(cmd).to be_an_instance_of Commands::SampleCommand
    end
  end
end
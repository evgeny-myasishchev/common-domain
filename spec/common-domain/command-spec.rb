require 'spec-helper'

describe CommonDomain::Command do
  module Commands
    include CommonDomain::Command::DSL
    
    command :SampleCommand, :aggregate_id, :name, :description
    command :HeadersOnlyCommand
    command :OtherCommand
    command :OtherCommand1, :aggregate_id
  end
  
  it "should have headers hash" do
    cmd = Commands::SampleCommand.new 'agg-1', 'name-1', 'descr-1'
    expect(cmd.headers).not_to be_nil
    expect(cmd.headers).to be_instance_of(Hash)
  end

  it "should initialize headers and attributes" do
    cmd = Commands::SampleCommand.new attributes: { aggregate_id: "aggregate-1", name: "name-1", description: "description-1" }, headers: {header1: 'header 1', header2: 'header 2'}
    expect(cmd.aggregate_id).to eql "aggregate-1"
    expect(cmd.name).to eql "name-1"
    expect(cmd.description).to eql "description-1"
    expect(cmd.headers).to eql(header1: 'header 1', header2: 'header 2')
  end
  
  it "should initialize headers only" do
    cmd = Commands::HeadersOnlyCommand.new headers: {header1: 'header 1', header2: 'header 2'}
    expect(cmd.headers).to eql(header1: 'header 1', header2: 'header 2')
    expect(cmd.attribute_names).to be_empty
  end
  
  it 'should initialize from params only' do
    cmd = Commands::SampleCommand.new aggregate_id: "aggregate-1", :name => "name-1", :description => "description-1"
    expect(cmd.aggregate_id).to eql 'aggregate-1'
    expect(cmd.attribute_names).to eql [:aggregate_id, :name, :description]
    expect(cmd.name).to eql 'name-1'
    expect(cmd.description).to eql 'description-1'
    expect(cmd.headers).to be_empty
  end
  
  describe "equality" do
    it "should do equality by all attributes" do
      left = Commands::SampleCommand.new aggregate_id: "aggregate-1", name: 'cmd 1', description: 'cmd 1 desc'
      right = Commands::SampleCommand.new aggregate_id: "aggregate-1", name: 'cmd 1', description: 'cmd 1 desc'

      expect(left == right).to be_truthy
      expect(left).to eql right
      
      left = Commands::SampleCommand.new aggregate_id: "aggregate-1", name: 'cmd 1-changed', description: 'cmd 1 desc'
      expect(left == right).to be_falsy
      expect(left).not_to eql right
      
      left = Commands::SampleCommand.new aggregate_id: "aggregate-1", name: 'cmd 1', description: 'cmd 1 desc-changed'
      expect(left == right).to be_falsy
      expect(left).not_to eql right
    end
    
    it "should do the equality by headers" do
      left = Commands::OtherCommand.new
      right = Commands::OtherCommand.new
      
      left.headers[:header1] = 'header-1'
      right.headers[:header1] = 'header-1'
      
      expect(left == right).to be_truthy
      expect(left).to eql right
      
      left.headers[:header1] = 'header-1-changed'
      expect(left == right).not_to be_truthy
      expect(left).not_to eql right
    end
  end
end
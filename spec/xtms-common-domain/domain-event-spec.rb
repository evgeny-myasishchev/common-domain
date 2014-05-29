require 'spec-helper'

describe CommonDomain::DomainEvent do
  class SampleEvent < CommonDomain::DomainEvent
    attr_accessor :name, :description
  end
  
  it "should initialize attributes" do
    event = SampleEvent.new "aggregate-1", :name => "name-1", :description => "description-1"
    event.aggregate_id.should eql "aggregate-1"
    event.name.should eql "name-1"
    event.description.should eql "description-1"
  end
  
  describe "attr" do
    it "should return a value for corresponding attribute" do
      event = SampleEvent.new "aggregate-1", :name => "name-1", :description => "description-1"
      event.attribute(:name).should eql 'name-1'
      event.attribute(:description).should eql 'description-1'
    end
    
    it "should return a value for the attribute if it was specified as a string key" do
      event = SampleEvent.new "aggregate-1", "name" => "name-1", "description" => "description-1"
      event.attribute(:name).should eql 'name-1'
      event.attribute(:description).should eql 'description-1'
    end
  end
  
  describe "equality" do
    it "should do equality by aggregate_id and version" do
      left = SampleEvent.new "aggregate-1"
      left.version = 1
      right = SampleEvent.new "aggregate-1"
      right.version = 1

      left.should == right
      left.should eql right
    end
    
    it "should do equality by all attributes" do
      left = SampleEvent.new "aggregate-1", name: 'name-1', description: 'description-1'
      left.version = 1
      right = SampleEvent.new "aggregate-1", name: 'name-1', description: 'description-1'
      right.version = 1

      left.should == right
      left.should eql right
      
      left.name = 'name-2'
      left.should_not == right
      left.should_not eql right
      
      left.name = right.name
      left.description = 'description-2'
      left.should_not == right
      left.should_not eql right
    end
  end
end
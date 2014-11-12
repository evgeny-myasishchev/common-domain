require 'spec-helper'

describe CommonDomain::DomainEvent do
  class SampleEvent < CommonDomain::DomainEvent
    attr_accessor :name, :description
  end
  
  it "should initialize attributes" do
    event = SampleEvent.new "aggregate-1", :name => "name-1", :description => "description-1"
    expect(event.aggregate_id).to eql "aggregate-1"
    expect(event.name).to eql "name-1"
    expect(event.description).to eql "description-1"
  end
  
  describe "attr" do
    it "should return a value for corresponding attribute" do
      event = SampleEvent.new "aggregate-1", :name => "name-1", :description => "description-1"
      expect(event.attribute(:name)).to eql 'name-1'
      expect(event.attribute(:description)).to eql 'description-1'
    end
    
    it "should return a value for the attribute if it was specified as a string key" do
      event = SampleEvent.new "aggregate-1", "name" => "name-1", "description" => "description-1"
      expect(event.attribute(:name)).to eql 'name-1'
      expect(event.attribute(:description)).to eql 'description-1'
    end
  end
  
  describe "equality" do
    it "should do equality by aggregate_id" do
      left = SampleEvent.new "aggregate-1"
      right = SampleEvent.new "aggregate-1"

      expect(left == right).to be_truthy
      expect(left).to eql right
    end
    
    it "should do equality by all attributes" do
      left = SampleEvent.new "aggregate-1", name: 'name-1', description: 'description-1'
      right = SampleEvent.new "aggregate-1", name: 'name-1', description: 'description-1'

      expect(left == right).to be_truthy
      expect(left).to eql right
      
      left.name = 'name-2'
      expect(left == right).to be_falsy
      expect(left).not_to eql right
      
      left.name = right.name
      left.description = 'description-2'
      expect(left == right).to be_falsy
      expect(left).not_to eql right
    end
  end
end
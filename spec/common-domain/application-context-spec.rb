require 'spec-helper'

describe CommonDomain::ApplicationContext do
  describe 'initialize' do
    it 'should assign dependencies as reader attributes' do
      deps = {
        dep1: 'The Dep 1',
        dep2: 'The Dep 2',
        dep3: 'The Dep 3'
      }
      subject = described_class.new deps
      expect(subject).to respond_to(:dep1)
      expect(subject.dep1).to eql deps[:dep1]
      
      expect(subject).to respond_to(:dep2)
      expect(subject.dep2).to eql deps[:dep2]
      
      expect(subject).to respond_to(:dep3) 
      expect(subject.dep3).to eql deps[:dep3]
    end
    
    it 'should define reader attributes on singleton class of the instance' do
      deps = { dep1: 'The Dep 1' }
      subject = described_class.new deps
      expect(described_class.instance_methods).not_to include :dep1
      expect(subject.singleton_methods).to include :dep1
    end
  end
  
  describe 'bootstrap' do
    it 'should setup all dependencies and create context' do
      counter = 0
      subject = described_class.bootstrap do
        with -> (deps) { deps[:dep1] = "The Dep #{counter += 1}" }
        with -> (deps) { deps[:dep2] = "The Dep #{counter += 1}" }
        with -> (deps) { deps[:dep3] = "The Dep #{counter += 1}" }
      end
      expect(subject).to be_an_instance_of described_class
      expect(subject.dep1).to eql 'The Dep 1'
      expect(subject.dep2).to eql 'The Dep 2'
      expect(subject.dep3).to eql 'The Dep 3'
    end
  end
end
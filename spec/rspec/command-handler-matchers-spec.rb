require 'spec-helper'

describe 'command handler matchers' do
  module Cmd
    include CommonDomain::Command::DSL
    command :CreateAccount, :login
    command :RenameAccount, :login
  end
  
  class DummyAggregate < CommonDomain::Aggregate
    def create_account(cmd)
      puts "create account: #{cmd}"
    end
    
    def rename_account(cmd)
    end
  end
  
  let(:repository) { double(:repository) }
  
  let(:handler) {
    klass = Class.new(CommonDomain::CommandHandler) do
      handle(Cmd::CreateAccount).with(DummyAggregate)
    end
    klass.new(repository)
  }
  
  describe 'handle_command' do
    it 'should match if the handler can handle the command' do
      matcher = handle_command(Cmd::CreateAccount.new(login: 'email-112'))
      expect(matcher.matches?(handler)).to be_truthy
    end
    
    it 'should not match if the handler can not handle the command' do
      matcher = handle_command(Cmd::RenameAccount.new(login: 'email-112'))
      expect(matcher.matches?(handler)).not_to be_truthy
    end
    
    describe 'with chain' do
      it 'should match if the command is routed to the specified aggregate' do
        matcher = handle_command(Cmd::CreateAccount.new('aggregate-100', login: 'email-112')).with(DummyAggregate)
        expect(matcher.matches?(handler)).to be_truthy
      end
      
      it 'should not match if the command is not routed to the specified aggregate' do
        handler.class.class_eval do
          on Cmd::RenameAccount do |cmd|
          end
        end
        
        matcher = handle_command(Cmd::RenameAccount.new('aggregate-100', login: 'email-112')).with(DummyAggregate)
        expect(matcher.matches?(handler)).not_to be_truthy
      end
    end
  end
end
describe CommonDomain::Messages::Dsl do
  let(:events_module) {
    Module.new do
      include CommonDomain::Messages::Dsl
      
      message :NoAttributesMessage
      message :SimpleMessage, :login, :password
    end
  }
end
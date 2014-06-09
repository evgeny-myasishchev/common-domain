RSpec::Matchers.define :be_an_aggregate do
  match do |actual|
    actual.is_a? CommonDomain::Aggregate
  end
  
  description do
    "be a kind of #{CommonDomain::Aggregate}"
  end
  
  failure_message do |actual|
    "\nexpected: \"#{actual}\" to be a kind of CommonDomain::Aggregate\ngot: #{actual.class}\n"
  end
  
  failure_message_when_negated do |actual|
    "\nexpected: \"#{actual}\" not to be a kind of CommonDomain::Aggregate"
  end
end
require_relative '../../test_helper'
 
describe Vuf::Profiler do
  subject { Vuf::Profiler.new }
 
  it "must parse options without errors" do
    subject.run(0.1)
    10000.times do 
      subject.start('test')
      sleep(rand(10)/1000)
      subject.stop('test')
    end
    subject.finalize
  end
end

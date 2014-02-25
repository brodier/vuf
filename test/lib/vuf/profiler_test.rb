require_relative '../../test_helper'
 
describe Vuf::Profiler do
  subject { Vuf::Profiler.new }
 
  it "must parse options without errors" do
    Vuf::Logger.outputters = Log4r::FileOutputter.new("profile_logger", {:filename => "test/tmp/log_profiler.log"})
    subject.run(0.1)
    10000.times do 
      subject.start('test')
      sleep(rand(10)/1000)
      subject.stop('test')
    end
    subject.finalize
    Vuf::Logger.outputters = Log4r::Outputter.stderr
  end
end

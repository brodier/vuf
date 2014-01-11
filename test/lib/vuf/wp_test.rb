require_relative '../../test_helper'

describe Vuf::WorkingPool do
  subject {  Vuf::WorkingPool.new(5) }
  
  it "must be a WorkingPool" do
    subject.must_be_instance_of(Vuf::WorkingPool)
  end
  
  it "must respond_to run" do
    subject.must_respond_to(:run)
  end

  it "must respond_to do" do
    subject.must_respond_to(:do)
  end
  
  it "must respond_to finalize" do
    subject.must_respond_to(:finalize)
  end

  it "must handle without error" do
    subject.run
    5.times do |i|
      subject.do { sleep(1) }
    end
    subject.finalize
  end
end


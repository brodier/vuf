require_relative '../../test_helper'

describe Vuf::Batch do
  subject { 
    Vuf::Batch.new(50) do |objQ|
      objQ.size.must_equal(50) unless objQ.empty?
    end
  }
  
  it "must respond to push" do
    subject.must_respond_to(:push)
    1000.times do |i|
      subject.push(i)
    end
  end
  
  it "must respond to flush" do
    subject.must_respond_to(:flush)
    1000.times do |i|
      subject.push(i)
    end
    subject.flush
  end  
  
end


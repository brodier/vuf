require_relative '../../test_helper'
class PoolKlass
  include Vuf::Pool
  attr_reader :i_index
  def initialize
    @@index ||= 0
    @@index += 1
    @i_index = @@index
  end
  
  def write(msg)
    @f = File.open(File.join("test", "tmp", "file_#{@i_index}.txt"),"w+")
    @f.write(msg)
    @f.close
  end
end

describe Vuf::Pool do
  subject {  
    class TestKlass
      include Vuf::Pool
      def initialize
      end
    end
    TestKlass
  }
  
  it "must not respond to new" do
    subject.wont_respond_to(:new)
  end
  
  it "must respond_to use_instance" do
    subject.must_respond_to(:instance)
  end
  
  it "must respond_to release" do
    subject.must_respond_to(:release)
  end
end


describe Vuf::Pool do

  subject { 5 }
  
  it "must create 5 Files" do
    wp = Vuf::WorkingPool.new(subject)
    wp.run
    100.times do |i|
      wp.do(i,i) { |i|
        begin
          writer = PoolKlass.instance
          writer.write("Message #{i.to_s}\n")
          sleep 0.01
          PoolKlass.release
        rescue => e
          Vuf::Logger.error "#{e}\n#{e.message}\n#{e.backtrace.join("\n")}"
        end
      }
    end
    wp.finalize
    Dir[File.join("test", "tmp","file_*.txt")].size.must_equal(subject)
  end
end
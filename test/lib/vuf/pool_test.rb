require_relative '../../test_helper'

describe Vuf::Pool do
  Logger = Vuf::Logger
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
  class PoolKlass
    include Vuf::Pool
    attr_reader :i_index
    def initialize
      @@index ||= 0
      @@index += 1
      @i_index = @@index
      @f = File.open(File.join("test", "tmp", "file_#{@@index}.txt"),"w+")
    end
    
    def write(msg)
      @f.write(msg)
    end
  end
    

  subject { 5 }
  
  it "must create 5 Files" do
    wp = Vuf::WorkingPool.new(subject)
    wp.run
    1000.times do |i|
      wp.do do 
        Logger.info "WP task #{i}\n"
        poolklass_instance = PoolKlass.instance
        Logger.info "Write message #{i} in instance(#{poolklass_instance.i_index})\n"
        poolklass_instance.write("Message #{i.to_s}\n")
        PoolKlass.release
      end
    end
    wp.finalize
    Dir[File.join("test", "tmp","file_*.txt")].size.must_equal(subject)
  end
end
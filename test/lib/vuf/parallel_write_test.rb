require_relative '../../test_helper'

describe Vuf::Pool do
  let(:temp_path) { File.join("test", "tmp")}
  class PoolKlass
    include Vuf::Pool
    attr_reader :i_index
    def initialize
      @@index ||= 0
      @@index += 1
      @i_index = @@index
      @f = File.open(File.join(temp_path, "file_#{@@index}.txt"),"w+")
    end
    def write(msg)
      puts "request write #{msg} on #{@f}"
      @f.write(msg)
    end
  end
    

  subject { 5 }
  
  it "must create 5 Files" do
    wp = Vuf::WorkingPool.new(subject)
    wp.run
    1000.times do |i|
      puts "times loop #{i}"
      wp.do do 
        puts "WP task #{i}"
        PoolKlass.use_instance do |poolklass_instance|
          puts "Write message #{i} in #{poolklass_instance.i_index}"
          poolklass_instance.write("Message #{i.to_s}\n")
        end
      end
    end
    Dir[File.join(temp_path,"file_*.txt")].size.must_equal(subject)
    wp.finalize
  end
end


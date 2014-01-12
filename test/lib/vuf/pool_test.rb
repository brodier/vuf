require_relative '../../test_helper'

describe Vuf::Pool do
  subject {  
    class PoolKlass
      include Vuf::Pool
      def initialize
      end
    end
    PoolKlass
  }
  
  it "must not respond to new" do
    subject.wont_respond_to(:new)
  end
  
  it "must respond_to use_instance" do
    subject.must_respond_to(:use_instance)
  end

end


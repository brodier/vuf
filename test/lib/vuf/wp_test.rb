require_relative '../../test_helper'

describe Vuf::WorkingPool do
  subject {  Vuf::WorkingPool.new(5) }
  
  it "must be a WorkingPool" do
    subject.must_be_instance_of(Vuf::WorkingPool)
  end
  
  it "must generate a field with computed value" do
    subject.decode(@buffer).first.get_value.must_equal("0012AB")
  end
  
  it "must also return remaining data" do
    subject.decode(@buffer).last.must_equal("")
  end

  it "must encode value prefixed with length" do
    subject.encode(@field).must_equal("0060012AB")
  end
end

describe Codec::Prefixedlength do
  before do
    @length = Codec::Numasc.new('length',3)
    @content = Codec::Strpck.new('content',0)
    @field = Codec::Field.new
    @field.set_value("0012AB")
    @buffer = "006" +["0012AB"].pack("H*")
  end

  subject { Codec::Prefixedlength.new('Test_lvar',@length,@content) }
  
  it "must be a Prefixedlength codec" do
    subject.must_be_instance_of(Codec::Prefixedlength)
  end
  
  it "must generate a field with computed value" do
    subject.decode(@buffer).first.get_value.upcase.must_equal("0012AB")
  end
  
  it "must also return remaining data" do
    subject.decode(@buffer).last.must_equal("")
  end

  it "must encode value prefixed with length" do
    subject.encode(@field).must_equal(@buffer)
  end
end


describe Codec::Headerlength do
  before do
    tag = Codec::Binary.new('T',1)
    length = Codec::Numbin.new('L',1)
    value = Codec::Numbin.new('V',0)
    tlv = Codec::Tlv.new('TAG',length,tag,value)
    @header = Codec::BaseComposed.new('HEADER')
    @header.add_sub_codec('H_TAG',tag)
    @header.add_sub_codec('H_TLV',Codec::Prefixedlength.new('*',length,tlv))
    @content = Codec::String.new('CONTENT',0)
    len = 6
    field_head = ['HEADER', [['H_TAG','AA'],['H_TLV',[['01',25],['02',len]]]]]
    field_content = ['CONTENT','STRING']
    field_array = [ field_head, field_content]
    @field_with_length = Codec::Field.from_array('Test_Headerlength',field_array)
    len = 0
    field_head = ['HEADER', [['H_TAG','AA'],['H_TLV',[['01',25],['02',len]]]]]
    field_array = [ field_head, field_content]
    @field_without_length = Codec::Field.from_array('Test_Headerlength',field_array)
    field_array = [field_content]
    @field_without_head = Codec::Field.from_array('Test_Headerlength',field_array)
    @buffer = ["AA06010119020106","STRING"].pack("H*A*")
  end

  subject { Codec::Headerlength.new('Test_Headerlength',@header,@content,'.H_TLV.02') }
  
  it "must be a Headerlength codec" do
    subject.must_be_instance_of(Codec::Headerlength)
  end
  
  it "must decode a field with computed value" do
    subject.decode(@buffer).first.must_equal(@field_with_length)
  end
  
  it "must also return remaining data" do
    subject.decode(@buffer + "REMAIN").last.must_equal("REMAIN")
  end

  it "must encode buffer with composed field [header,content]" do
    subject.encode(@field_without_length).must_equal(@buffer)
  end
  
  it "must raise EncodingException if missing header field" do
    proc { subject.encode(@field_without_head)}.must_raise(Codec::EncodingException)
  end
  
end

describe Codec::Tagged do
  before do
    @field1 = Codec::Field.new('01',12)
    @field2 = Codec::Field.new('02','ABC')
    @buffer1 = "01012"
    @buffer2 = "02ABC"
  end

  subject { c = Codec::Tagged.new('Test_tagged',Codec::String.new('*',2)) 
            c.add_sub_codec('01',Codec::Numasc.new('*',3))
            c.add_sub_codec('02',Codec::String.new('*',3))
            c
          }
  
  it "must be a Tagged codec" do
    subject.must_be_instance_of(Codec::Tagged)
  end
  
  it "must generate a field with computed value" do
    subject.decode(@buffer1).first.must_equal(@field1)
  end
  
  it "must generate a field with computed value" do
    subject.decode(@buffer2).first.must_equal(@field2)
  end  

  it "must encode value prefixed with length" do
    subject.encode(@field1).must_equal(@buffer1)
  end

  it "must encode value prefixed with length" do
    subject.encode(@field2).must_equal(@buffer2)
  end
end

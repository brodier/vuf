require_relative '../../test_helper'
 
class TestSession
  REPLIES = {
    "IPDU_CN" => "IPDU_AC",
    "MSG_804" => "MSG_814",
    "MSG_306" => "MSG_316",
    "MSG_246" => "MSG_256",
    "MSG_506" => "MSG_516"
  }
  def initialize(socket)
    @sock = socket
    @step = 0
  end
  
  def handle(msg)
      if @step != REPLIES.keys.index(msg)
        Vuf::Logger.error "Error received #{msg} on step #{@step}"
      end
      
      @step += 1
      
      reply = REPLIES[msg]
      reply ||= "Error"
      begin
        @sock.send reply,0    
      rescue => e
        Vuf::Logger.error "Error on send #{reply} for  #{@sock} => [#{e}]
            #{e.message}
            #{e.backtrace.join("\n")}"        
      end
  end
  
  def finalize
    if @step != 5
      Vuf::Logger.error "Error finalize on step #{@step}"
    end
  end
end


class TestClient
  def run
    sockets = []
    done = 0 ; done_mutex = Mutex.new
    FIRST_MSG = "IPDU_CN"
    REPLIES = {
      "IPDU_AC" => "MSG_804",
      "MSG_814" => "MSG_306",
      "MSG_316" => "MSG_246",
      "MSG_256" => "MSG_506",
      "MSG_516" => nil
    }
    nb_run=0
    until done == 1000
      while sockets.size < 20 && nb_run < 1000
        nb_run += 1
        s =  TCPSocket.open('localhost',3527)
        s.send FIRST_MSG, 0
        sockets << s
      end
      
      rsl, = IO.select(sockets,[],[],1)
      
      unless rsl.nil?
        rsl.each do |s|
          reply = s.recv(1024)
          req = REPLIES[reply]
          if reply == "MSG_516"
            s.close
            done_mutex.synchronize { done += 1}
            sockets.delete(s)
            Vuf::Logger.info "#{done}"
          elsif req.nil?
            Vuf::Logger.error "Error unknown reply #{reply}"
            sleep 0.2
          else
            s.send req, 0
          end
        end
      end
    end
  end
end

describe Vuf::Server do
  subject { Vuf::Server.new(3527,TestSession) }
 
  it "must parse options without errors" do
    # Run the server with logging enabled (it's a separate thread).
    subject.start
    TestClient.new.run
    server.shutdown
  end
end

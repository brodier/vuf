require_relative '../../test_helper'

STEPS = ["IPDU_CN", "IPDU_AC", "MSG_804", "MSG_814", "MSG_306", "MSG_316", 
  "MSG_246",  "MSG_256", "MSG_506",  "MSG_516", nil]

 
class TestSession
  attr_reader :step
  def initialize(socket)
    @sock = socket
    @step = 0
  end
  
  def start
    @sock.send STEPS.first, 0
    @step += 1
  end
  
  def handle(msg)
      curr_step = STEPS.index(msg)
      if @step != curr_step
        Vuf::Logger.error "Error received #{msg} on step #{@step}"
        return nil
      end      
      @step += 1
      reply = STEPS[@step]
      return nil if reply.nil?
      no_reply = true
      begin
        @sock.send reply,0    
        no_reply = false
      rescue => e
        Vuf::Logger.error "Error on send #{reply} for  #{@sock} => [#{e}]
            #{e.message}
            #{e.backtrace.join("\n")}"        
      ensure 
        if no_reply
          Vuf::Logger.error "No reply send on session #{@sock} for msg #{msg} / reply #{reply} on step #{@step}"
        end
      end
      @step += 1
      return @step
  end
  
  def finalize
    if @step != (STEPS.size - 1)
      Vuf::Logger.error "Error finalize on step #{@step}"
    end
  end
end


class TestClient
  def initialize(nb_req)
    @nb_req = nb_req
  end
  
  def run
    sockets = []
    sessions = {}
    done = 0 ; done_mutex = Mutex.new
    nb_run=0
    until done == @nb_req
      while sockets.size < 20 && nb_run < @nb_req
        nb_run += 1
        s =  TCPSocket.open('localhost',3527)
        sockets << s
        sessions[s] = TestSession.new(s)
        sessions[s].start
      end
      
      rsl, = IO.select(sockets,[],[],1)
      
      unless rsl.nil?
        rsl.each do |s|
          reply = s.recv(1024)
          sess = sessions[s]
          ret = sess.handle(reply)
          if ret.nil?
            s.close
            done_mutex.synchronize { done += 1}
            sockets.delete(s)
            sessions.delete(s)
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
    TestClient.new(100).run
    subject.shutdown
  end
end

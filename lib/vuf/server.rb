module Vuf
  class Server
    
    def initialize(port, session_klass)
      @port = port
      @sessions_ctx = {}
      @server_thread = nil
      @closing_q = Queue.new
      @session_klass = session_klass
      @wp = Vuf::WorkingPool.new(4)
      @wp.run
    end

    def start
      if @server_thread.nil?
        @running = true
        @server_thread = Thread.new do
          Logger.debug "Server Starting"
          begin
            @server = TCPServer.new @port
            @s_list = [@server]
            while @running
              close_ended_sessions
              rsl, = IO.select(@s_list,[],[],1)
              next if rsl.nil? # Timeout
              accept(rsl) # Handle acceptance of new incoming session
              rsl.each { |s| serve s }
            end
          rescue => e
            Logger.error "Server Error [#{e}]
              #{e.message}
              #{e.backtrace.join("\n")}"
          end
        end
      end
    end
    
    def shutdown
      @running = false
      @server_thread.join unless @server_thread.nil?
      @server_thread = nil
    end    
    
    private
    
    def accept(selected)
      serv = selected.delete(@server)
      if serv
        sock = serv.accept
        @s_list << sock
        @sessions_ctx[sock] = @session_klass.new(sock)
      end
    end
    
    def serve(sock)
      msg_recv = sock.recv_nonblock(1024)
      if msg_recv.empty?
        @closing_q << sock
      else
        session = @sessions_ctx[sock]
        @wp.do(session,session,msg_recv) do |sess,msg|
          ret = sess.handle(msg)
          if ret.nil?
            Logger.error "Handle return nil on msg #{msg} at step #{sess.step}"
          end
        end
      end
    end
    
    def close_ended_sessions
      until @closing_q.empty?
        s = @closing_q.pop
        session = @sessions_ctx.delete(s)
         if session
           @wp.do(session,session,s) do |sess,sock|
             sess.finalize                
             sock.close
           end
         end
        @s_list.delete(s) 
      end    
    end
  end
end


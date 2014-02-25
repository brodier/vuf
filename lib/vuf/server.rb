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
    
    def serve(sock)
      msg_recv = sock.recv_nonblock(1024)
      if msg_recv.empty?
        session = @sessions_ctx.delete(sock)
        session.finalize unless session.nil?
        @closing_q << sock
      else
        session = @sessions_ctx[sock]
        @wp.do(session,session,msg_recv) do |sess,msg|
          sess.handle(msg)
        end
      end
    end
    
    def start
      if @server_thread.nil?
        @running = true
        @server_thread = Thread.new do
          puts "Server Starting"
          begin
            @server = TCPServer.new @port
            s_list = [@server]
            while @running
              until @closing_q.empty?
                s = @closing_q.pop
                s.close
                s_list.delete(s) 
              end
              rsl, = IO.select(s_list,[],[],1)
              unless rsl.nil? # Timeout
                rsl.each do |s|
                  if s == @server
                    sock = s.accept
                    s_list << sock
                    @sessions_ctx[sock] = @session_klass.new(sock)
                  else
                    serve s
                  end
                end
              end
            end
          rescue => e
            puts "Server Error [#{e}]
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
  end
end


module Vuf
  class Profiler
    def initialize
      @mutex = Mutex.new
      @delay = 
      @stats = {:counter => {}, :time => {}, :avtime => {}}
      @timers = {}
      @enable = false
    end
    
    def enable ; @enable = true ; end
    def disable ; @enable = false ; end
    
    def count(label)
      @mutex.synchronize {
        @stats[:counter][label] ||= 0
        @stats[:counter][label] += 1
      }
    end
    def start(label)
      @mutex.synchronize { @timers[[Thread.current,label]] = Time.new }
    end
    
    def stop(label)
      new_time = Time.new
      @mutex.synchronize { 
        time = @timers.delete([Thread.current,label])
        if time
          @stats[:time][label] ||= []
          @stats[:time][label] << new_time - time
        end
      }
    end
    
    def result
      counter_stat = [] ; time_stat = []
      error = nil
      @mutex.synchronize {
        begin 
          @stats[:counter].each{|k,v| counter_stat << "#{k} => #{v.to_s.rjust(10,' ')}" }
          @stats[:time].each{ |k,v|
            # retrieve previous av_time and number of mesures (nbdata)
            av_time,nbdata = @stats[:avtime][k]
            # Init values if not already done
            av_time ||= 0 ; nbdata ||= 0
            # retrieve cumultime from previous average time
            cumul_time = av_time * nbdata
            unless v.nil?
              v.each{|time| cumul_time += time}
              # increase number of mesures with number of new mesure
              nbdata += v.size
            end
            av_time = cumul_time / nbdata
            time_stat << "#{k.to_s.rjust(20,' ')} => #{av_time.round(8).to_s.rjust(12,' ')} s/op " + 
            "[#{nbdata.to_s.rjust(12,' ')} op| #{(nbdata*av_time).round(2).to_s.rjust(8,' ')} s]"
            @stats[:avtime][k] = [av_time,nbdata]
            @stats[:time][k] = nil
          }      
        rescue => e
          Logger.error {"Error in statistic #{e.message}\n#{e.backtrace.join("\n")}"}
          error = e
        end
      }
      raise error if error
      [counter_stat, time_stat].flatten.join("\n  - ")
    end

    def finalize
      return if @stat_thread.nil? || !@stat_thread.alive?
      @running = false
      @stat_thread.wakeup
      @stat_thread.join
      @stat_thread=nil
    end
    
    def run(delay=10)
      return if @stat_thread
      
      @stat_thread = Thread.new do
        enable ; GC::Profiler.enable ; @running = true
        while @running
          start('total') ; sleep(delay) ; stop('total')
          gc_result = [] ; GC::Profiler.result.each_line{|l| gc_result << l}
          Logger.info "Profiling Result : \n  - #{result}\n#{gc_result.shift}#{gc_result.first}#{gc_result.last}"
        end
        GC::Profiler.disable ; disable
      end
      # Ensure that finaliz was call at exit
      Kernel.at_exit { finalize }
    end
    
  end
end
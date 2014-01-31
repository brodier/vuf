module Vuf
  class WorkingPool
    ENDING_TASK="ENDING_TASK"
    
    def initialize(nb_workers, max_pending_tasks=nil)
      @nb_workers = nb_workers
      if max_pending_tasks.nil?
        @wq = Queue.new
      else
	      @wq = SizedQueue.new(max_pending_tasks)
      end
      @channels_mutex = Mutex.new
      @channels = {}
      @channelsQ = Array.new(@nb_workers){ Queue.new }
    end

    def run
      if @workers.nil?
        @workers=[]
        @nb_workers.times do 
	        @workers << Thread.new do
	          works
	        end
        end
	    end
    end

    def do(channel=nil, *args, &task)
      @wq.push([channel,task,args])
    end

    def finalize
      return if @workers.nil?
      @nb_workers.times do 
        @wq.push(ENDING_TASK)
      end
      @workers.each do |worker|
        worker.join
      end
      @workers=nil
    end
    
    private
    
    def try_lock_channel(channel,task, args)
      new_channel_q = nil
      @channels_mutex.synchronize {
        if @channels[channel].nil?
	        new_channel_q = @channelsQ.shift
          raise "Missing queue in working pool" unless new_channel_q.instance_of?(Queue)
          @channels[channel]=new_channel_q
	      end
        @channels[channel].push([task, args])
      }
      return new_channel_q
    end
    
    def is_clear(channel)
      is_clear=nil
      @channels_mutex.synchronize{
        is_clear = @channels[channel].empty?
	      @channelsQ << @channels.delete(channel) if is_clear
      }
      return is_clear
    end

    def works
      task=nil
      until ENDING_TASK == (channel, task, args = @wq.pop)
        channelQ = nil
        channelQ = try_lock_channel(channel, task, args) unless channel.nil?
        unless channelQ.nil?
          until is_clear(channel)
            task,args = channelQ.pop
            begin
              task.call(*args)
            rescue => e
              Logger.error "Worker catch a task exception :\n#{e.message}\n#{e.backtrace.join("\n")}"
            end
          end
          channelQ = nil
        end
      end
    end
  end
end


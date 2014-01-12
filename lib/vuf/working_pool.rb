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

    def do(channel=nil,&task)
      @wq.push([channel,task])
    end

    def finalize
      return if @workers.nil?
      @nb_workers.times do 
        @wq.push(ENDING_TASK)
      end
      @workers.each do |worker|
        worker.join
      end
    end
    
    private
    
    def try_lock_channel(channel,task)
      new_channel_q = nil
      @channels_mutex.synchronize {
        if @channels[channel].nil?
	        new_channel_q = @channelsQ.shift
          @channels[channel]=new_channel_q
	      end
      }
      @channels[channel].push(task)
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
      until ENDING_TASK == (task= @wq.pop)
        channel = task.first
        task = task.last
        channelQ = nil
	channelQ = try_lock_channel(channel,task) unless channel.nil?
        if channelQ.nil?
	  task.call
        else
          channelQ.pop.call until is_clear(channel)
	end
      end
    end
  end
end


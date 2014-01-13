module Vuf
  class Batch
    def initialize(size,&batch)
      @mutex = Mutex.new
      @batchQ = SizedQueue.new(size)
      @batch = batch
    end
    
    def push(obj)
      @batchQ.push(obj)
      objsToProc = get_objs(@batchQ.max)
      @batch.call(objsToProc) unless objsToProc.nil?
    end
    
    def flush
      objsToProc = get_objs(0)
      @batch.call(objsToProc)
    end
    
    private
    def get_objs(size_condition)
      objToProc = nil
      @mutex.synchronize do
        if size_condition <= @batchQ.size
          objToProc = []
          objToProc <<  @batchQ.pop until @batchQ.empty?
          @batchQ.clear
        end
      end     
      return objToProc
    end

  end
end

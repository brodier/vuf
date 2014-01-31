module Vuf
  class Batch
    def initialize(size,&batch)
      @mutex = Mutex.new
      @batchQ = []
      @size = size
      @batch = batch
    end
    
    def push(obj)
      @mutex.synchronize { @batchQ << obj }
      objsToProc = get_objs(@size)
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
          objToProc = @batchQ
          @batchQ = []
        end
      end     
      return objToProc
    end

  end
end

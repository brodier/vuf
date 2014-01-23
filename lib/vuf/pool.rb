module Vuf
  module Pool
    # Raises a TypeError to prevent cloning.
    def clone
      raise TypeError, "can't clone instance of Pool #{self.class}"
    end

    # Raises a TypeError to prevent duping.
    def dup
      raise TypeError, "can't dup instance of Pool #{self.class}"
    end

    # By default, do not retain any state when marshalling.
    def _dump(depth = -1)
      ''
    end

    module PoolClassMethods # :nodoc:

      def clone # :nodoc:
        Pool.__init__(super)
      end

      # By default calls instance(). Override to retain singleton state.
      def _load(str)
        raise TypeError, "can't _load Pool #{self.class}"
      end

      private

      def inherited(sub_klass)
        super
        Pool.__init__(sub_klass)
      end
    end

    class << Pool # :nodoc:
      def __init__(klass) # :nodoc:
        klass.instance_eval {
          @pool__instances__ = Queue.new
          @used__instances__ = Hash.new
          @pool__mutex__ = Mutex.new
        }
        
        def klass.instance # :nodoc:
          instance__ = nil
          @pool__mutex__.synchronize do
            instance__ = @used__instances__[Thread.current]
            if instance__.nil? && @pool__instances__.size > 0
              instance__ = @pool__instances__.pop 
            end
            instance__ = new() if instance__.nil?
            @used__instances__[Thread.current] = instance__
          end
          instance__
        end

        def klass.release # :nodoc:
          instance__ = nil
          @pool__mutex__.synchronize do
            instance__ = @used__instances__.delete(Thread.current)
            @pool__instances__.push(instance__) unless instance__.nil?
          end
          !instance__.nil?
        end

        def klass.count
          count = 0
          @pool__mutex__.synchronize do
            count = @pool__instances__.size + @used__instances__.size
          end
          return count
        end

        def klass.running
          count = 0
          @pool__mutex__.synchronize do
            count = @used__instances__.size
          end
          return count
        end
        
        def klass.finalize # :nodoc:
          @pool__mutex__.synchronize do
            until @pool__instances__.empty?
              i = @pool__instances__.pop
              i.finalize if i.respond_to?(:finalize)
            end
          end
        end
        
        klass
      end

      private

      # extending an object with Pool is a bad idea
      undef_method :extend_object

      def append_features(mod)
        #  help out people counting on transitive mixins
        unless mod.instance_of?(Class)
          raise TypeError, "Inclusion of the OO-Singleton module in module #{mod}"
        end
        super
      end

      def included(klass)
        super
        klass.private_class_method :new, :allocate
        klass.extend PoolClassMethods
        Pool.__init__(klass)
      end
    end
  end
end

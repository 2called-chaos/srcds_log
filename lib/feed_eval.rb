module SrcdsLog
  class FeedEval
    def initialize feeds, str
      @feeds = feeds
      @str = str

      @feeds.each do |name, filter|
        self.singleton_class.__send__(:define_method, name) { filter.call }
      end
    end

    def eval!
      eval(@str)
    rescue StandardError => ex
      warn "Error while filtering via feeds, aborting..."
      throw :abort_execution, ex
    end
  end
end

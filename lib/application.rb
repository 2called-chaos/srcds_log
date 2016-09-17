module SrcdsLog
  class Application
    include Colorize
    include Helper
    include Actions

    attr_reader :env, :argv, :argf, :opts, :feeds

    def initialize(env, argv, argf)
      @env, @argv, @argf = env, argv, argf
      @feeds = {}
      @opts = {
        cut: false,
        benchmark: true,
        debug: false,
        dispatch: :loop,
        colorize: true,
        show_hidden: false,
        show_attributes: false,
        feeds: false,
      }
      init_params!
    end

    def init_feeds! &filter
      filter.call if filter
      @feval = FeedEval.new(@feeds, @opts[:feeds]) if @opts[:feeds]
    end

    def init_params!
      @opt = OptionParser.new
      @opt.banner = "Usage: srcds_log [options]"
      @opt.on("-a", "--attributes", "Show attributes of each line") { @opts[:show_attributes] = true }
      @opt.on("-b", "--benchmark", "Benchmark parsing performance") { @opts[:benchmark] = true }
      @opt.on("-c", "--cut", "Cut output to terminal width") { @opts[:cut] = true }
      @opt.on("-f", "--feeds FEEDS", "Filter via feeds (use () || and &&)") {|f| @opts[:feeds] = f }
      @opt.on("-d", "--debug", "Enable debug output") { @opts[:debug] = true }
      @opt.on("-h", "--help", "Shows this help") { @opts[:dispatch] = :help }
      @opt.on("-m", "--monochrome", "Don't colorize output") { @opts[:colorize] = false }
      @opt.on("-u", "--update", "Updates self") { @opts[:dispatch] = :update }
      @opt.on("-s", "--show-hidden", "Show hidden lines") { @opts[:show_hidden] = true }
      @opt.on("-v", "--version", "Shows version information") { @opts[:dispatch] = :version }

      begin
        @opt.parse!(argv)
      rescue
        puts "#{$@[0]}: #{$!.message} (#{$!.class})"
        $@[1..-1].each{|m| puts "\tfrom #{m}" }
        puts nil, "  -------------", nil, "  !> #{$!.message} (#{$!.class})", nil
        exit 1
      end
    end

    def dispatch &filter
      if respond_to?(:"dispatch_#{@opts[:dispatch]}")
        __send__(:"dispatch_#{@opts[:dispatch]}", &filter)
      else
        raise("Unable to dispatch unknown action `#{@opts[:dispatch] || "NOT_GIVEN"}'")
      end
      exit 0
    end

    def feed *names, &filter
      names.each {|n| @feeds[n.to_sym] = filter }
    end

    def default &filter
      @feeds[:__default] = filter
    end
  end
end

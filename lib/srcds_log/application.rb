module SrcdsLog
  class Application
    include Colorize
    include Helper
    include Actions

    attr_reader :env, :argv, :argf, :opts, :feeds, :feeds_desc, :finalizer

    def initialize(env, argv, argf)
      @env, @argv, @argf = env, argv, argf
      @feeds = {}
      @feeds_desc = {}
      @finalizer = { __everytime: [] }
      @opts = {
        cut: false,
        benchmark: false,
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
      @feval = FeedEval.new(self, @feeds, @opts[:feeds]) if @opts[:feeds]
    end

    def init_params!
      @opt = OptionParser.new
      @opt.banner = "Usage: srcds_log [options]"
      @opt.on("-a", "--attributes", "Show attributes of each line") { @opts[:show_attributes] = true }
      @opt.on("-b", "--benchmark", "Benchmark parsing performance") { @opts[:benchmark] = true }
      @opt.on("-c", "--cut", "Cut output to terminal width") { @opts[:cut] = true }
      @opt.on("-d", "--debug", "Enable debug output") { @opts[:debug] = true }
      @opt.on("-f", "--feeds FEEDS", "Filter via feeds (use () || and &&)") {|f| @opts[:feeds] = f }
      @opt.on("-h", "--help", "Shows this help") { @opts[:dispatch] = :help }
      @opt.on("-l", "--list-feeds", "List available feeds") { @opts[:dispatch] = :list_feeds }
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

    def should_draw?
      if @feval
        @feval.eval!
      elsif @feeds[:__default]
        @feeds[:__default].call
      else
        !$rec.hidden? || @opts[:show_hidden]
      end
    end

    def init_benchmark
      if @opts[:benchmark]
        finalize do
          puts "----------- Benchmark ----------"
          puts "  Lines: #{$lines_processed} (#{$lines_drawn} (#{"%.2f" % ($lines_drawn.to_f / $lines_processed * 100)}%) drawn / #{($lines_processed - $lines_drawn)} (#{"%.2f" % (($lines_processed - $lines_drawn).to_f / $lines_processed * 100)}%) hidden)"
          puts "Runtime: #{human_seconds($loop_time)} (#{$loop_time}s)"
          puts "Lines/s: #{"%.4f" % ($lines_processed.to_f / $loop_time)}"
          puts "Slowest: #{human_seconds($slowest_run[0])} (#{$slowest_run[0]}) » #{$slowest_run[1]}" if $slowest_run
          puts "Fastest: #{human_seconds($fastest_run[0])} (#{$fastest_run[0]}) » #{$fastest_run[1]}" if $fastest_run
          puts "---------- /Benchmark ----------"
        end
      end
    end

    def dispatch &filter
      if respond_to?(:"dispatch_#{@opts[:dispatch]}")
        __send__(:"dispatch_#{@opts[:dispatch]}", &filter)
      else
        raise("Unable to dispatch unknown action `#{@opts[:dispatch] || "NOT_GIVEN"}'")
      end
      exit 0
    ensure
      finalizer_to_run = @finalizer[:__everytime].dup
      @finalizer.each {|n,f| finalizer_to_run += f if @opts[:feeds] && @opts[:feeds][n.to_s] }

      finalizer_to_run.each do |f|
        begin
          f.call(self)
        rescue
          puts "#{$@[0]}: #{$!.message} (#{$!.class})"
          $@[1..-1].each{|m| puts "\tfrom #{m}" }
          puts nil, "  -------------", nil, "  !> #{$!.message} (#{$!.class})", nil
        end
      end
    end

    def feed *names, &filter
      opts = names.last.is_a?(Hash) ? names.pop : {}
      names.each do |n|
        @feeds[n.to_sym] = filter
        @feeds_desc[n.to_sym] = opts[:desc]
      end
    end

    def default &filter
      @feeds[:__default] = filter
    end

    def finalize *on, &finalizer
      if on.any?
        on.each do |o|
          (@finalizer[o.to_sym] ||= []) << finalizer
        end
      else
        @finalizer[:__everytime] << finalizer
      end
    end
  end
end

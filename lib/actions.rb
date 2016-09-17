module SrcdsLog
  module Actions
    def dispatch_update
      print_version
      uri = URI.parse(UPDATE_URL)
      res = Net::HTTP.get_response(uri)

      if res.is_a?(Net::HTTPSuccess)
        File.open("#{__FILE__}.update", "w") {|f| f << res.body }
        FileUtils.mv("#{__FILE__}.update", __FILE__)
        FileUtils.chmod "+x", __FILE__
        puts `#{__FILE__} -v`.strip
      else
        puts "Update failed! Got #{res}"
        exit 1
      end

      puts "Updated?!"
    end

    def dispatch_version
      puts "Current srcds_log version is #{VERSION}"
    end

    def dispatch_help
      puts @opt.to_s
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

    def dispatch_loop &filter
      lines_processed = 0
      lines_drawn = 0
      fastest_run = false
      slowest_run = false
      filter.call
      init_feeds!
      loop_time = runtime do
        ARGF.each_line do |l|
          lines_processed += 1

          rec_time = runtime do
            v = catch :abort_execution do
              begin
                next if l.strip.empty?
                $rec = Line.new(l)
                out = []
                if should_draw?
                  lines_drawn += 1
                  $rec.draw(self, out)
                end
                out.each{|line| puts cut line }
              rescue StandardError => ex
                puts nil, "  -------------", nil, "  ?> #{l.inspect}", "  !> #{ex.message} (#{ex.class})", nil
                puts "#{ex.backtrace[0]}: #{ex.message} (#{ex.class})"
                ex.backtrace[1..-1].each{|m| puts "\tfrom #{m}" }
              ensure
                $rec = nil
              end
            end

            if v.is_a?(StandardError)
              puts nil, "  -------------", nil, "  ?> #{l.inspect}", "  !> #{v.message} (#{v.class})", nil
              puts "#{v.backtrace[0]}: #{v.message} (#{v.class})"
              v.backtrace[1..-1].each{|m| puts "\tfrom #{m}" }
              exit 1
            end
          end
          if @opts[:benchmark]
            slowest_run = [rec_time, l] if !slowest_run || rec_time >= slowest_run[0] && !l.strip.empty?
            fastest_run = [rec_time, l] if !fastest_run || rec_time <= fastest_run[0] && !l.strip.empty?
          end
        end
      end

      # benchmark
      if @opts[:benchmark]
        puts nil, "---------- Benchmark ----------"
        puts "  Lines: #{lines_processed} (#{lines_drawn} (#{"%.2f" % (lines_drawn.to_f / lines_processed * 100)}%) drawn / #{(lines_processed - lines_drawn) * 100} (#{"%.2f" % ((lines_processed - lines_drawn).to_f / lines_processed * 100)}%) hidden)"
        puts "Runtime: #{human_seconds(loop_time)} (#{loop_time}s)"
        puts "Lines/s: #{"%.4f" % (lines_processed.to_f / loop_time)}"
        puts "Slowest: #{human_seconds(slowest_run[0])} (#{slowest_run[0]}) » #{slowest_run[1]}" if slowest_run
        puts "Fastest: #{human_seconds(fastest_run[0])} (#{fastest_run[0]}) » #{fastest_run[1]}" if fastest_run
      end
    end
  end
end

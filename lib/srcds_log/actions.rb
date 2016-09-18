module SrcdsLog
  module Actions
    def dispatch_update
      dispatch_version
      if res = system(%{cd "#{APP_ROOT}" && git pull})
        puts c("Updated?!", :green)
      else
        puts c("Automatic update failed! Run `git pull' manually.", :red)
        exit 1
      end
    end

    def dispatch_version
      puts "Current srcds_log version is #{VERSION}"
    end

    def dispatch_help
      puts @opt.to_s
    end

    def dispatch_list_feeds &filter
      init_feeds!(&filter)
      puts c("Listing available feeds:")
      feed_list = @feeds.keys.sort
      fl_max = feed_list.map(&:length).max
      feed_list.each do |n|
        next if n == :__default
        puts c("  #{n.to_s.rjust([60, fl_max].min, " ")}", :blue) << c(" #{@feeds_desc[n]}")
      end
    end

    def dispatch_loop &filter
      $lines_processed = 0
      $lines_drawn = 0
      $fastest_run = false
      $slowest_run = false
      init_feeds!(&filter)
      init_benchmark

      $loop_time = runtime do
        ARGF.each_line do |l|
          $lines_processed += 1

          rec_time = runtime do
            v = nil
            n = catch :next do
            v = catch :abort_execution do
              begin
                next if l.strip.empty?
                $rec = Line.new(l)
                out = []
                if should_draw?
                  $lines_drawn += 1
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
            end

            if v.is_a?(StandardError)
              puts nil, "  -------------", nil, "  ?> #{l.inspect}", "  !> #{v.message} (#{v.class})", nil
              puts "#{v.backtrace[0]}: #{v.message} (#{v.class})"
              v.backtrace[1..-1].each{|m| puts "\tfrom #{m}" }
              exit! 1
            end
          end
          if @opts[:benchmark]
            $slowest_run = [rec_time, l] if !$slowest_run || rec_time >= $slowest_run[0] && !l.strip.empty?
            $fastest_run = [rec_time, l] if !$fastest_run || rec_time <= $fastest_run[0] && !l.strip.empty?
          end
        end
      end
    end
  end
end

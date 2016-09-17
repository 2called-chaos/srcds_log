module SrcdsLog
  module Helper
    def human_seconds secs
      secs = secs.to_i
      t_minute = 60
      t_hour = t_minute * 60
      t_day = t_hour * 24
      t_week = t_day * 7
      "".tap do |r|
        if secs >= t_week
          r << "#{secs / t_week}w "
          secs = secs % t_week
        end

        if secs >= t_day || !r.empty?
          r << "#{secs / t_day}d "
          secs = secs % t_day
        end

        if secs >= t_hour || !r.empty?
          r << "#{secs / t_hour}h "
          secs = secs % t_hour
        end

        if secs >= t_minute || !r.empty?
          r << "#{secs / t_minute}m "
          secs = secs % t_minute
        end

        r << "#{secs}s" unless r.include?("d")
      end.strip
    end

    def human_bytes bytes
      return false unless bytes
      {
        'B'  => 1024,
        'KB' => 1024 * 1024,
        'MB' => 1024 * 1024 * 1024,
        'GB' => 1024 * 1024 * 1024 * 1024,
        'TB' => 1024 * 1024 * 1024 * 1024 * 1024
      }.each_pair { |e, s| return "#{"%.2f" % (bytes.to_f / (s / 1024)).round(2)} #{e}" if bytes < s }
    end

    def winsize
      IO.console.winsize
    end

    def cut output_map
      maxlength = winsize[1]
      length = 0
      "".tap do |r|
        output_map.each do |str, color|
          str = str.to_s unless str.is_a?(String)
          if (!@opts[:cut] || maxlength == 0) || length + str.length <= maxlength
            r << c(str, color)
            length += str.length
          else
            r << c(str[0...(maxlength - length)], color)
            break
          end
        end
      end
    end

    def strbool v
      v = true if ["true", "t", "1", "y", "yes", "on"].include?(v)
      v = false if ["false", "f", "0", "n", "no", "off"].include?(v)
      v
    end

    def format_time time, opts = {}
      opts = { short: true, space: true}.merge(opts)
      if opts[:short]
        r = [time ? time.strftime("%H:%M:%S") : "??:??:??", time ? :cyan : :black]
      else
        r = [time ? time.strftime("%Y-%m-%d %H:%M:%S") : "????-??-?? ??:??:??", time ? :cyan : :black]
      end
      r[0] << " " if opts[:space]
      r
    end

    def runtime &block
      start_time = Time.now
      block.call
    ensure
      return Time.now - start_time
    end
  end
end

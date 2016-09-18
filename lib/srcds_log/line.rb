module SrcdsLog
  class Line
    include Classifiers
    include Helper
    RE_DATE = '(?:(?:[0]?[1-9]|[1][012])[-:\\/.](?:(?:[0-2]?\\d{1})|(?:[3][01]{1}))[-:\\/.](?:(?:[1]{1}\\d{1}\\d{1}\\d{1})|(?:[2]{1}\\d{3})))(?![\\d])'
    RE_TIME = '(?:(?:(?:[0-1][0-9])|(?:[2][0-3])|(?:[0-9])):(?:[0-5][0-9])(?::[0-5][0-9])?(?:\\s?(?:am|AM|pm|PM))?)'
    RE_IPV4 = '(?:(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))(?![\\d])'
    RE_NTAG_WT = '(.+)<([0-9]+)><(BOT|STEAM_[0-9:]+)><(CT|TERRORIST|Unassigned)?>'
    RE_COORD = '(?:\[(-?[0-9]+) (-?[0-9]+) (-?[0-9]+)\])'
    attr_reader :time, :data, :original_data, :categories, :attributes

    def initialize line
      @line = "#{line}".strip
      @regexp = /\AL (#{RE_DATE} - #{RE_TIME}): (.*)\z/
      @match = @line.match(@regexp)
      @time = false
      @data = false
      @hidden = false
      @original_data = false
      @classified = false
      @attributes = {}
      @categories = []
      @data_color = :yellow

      if @match
        @time = Time.strptime(@match[1], "%m/%d/%Y - %H:%M:%S")
        @data = @match[2].strip
        @original_data = @data.dup
        classify
      else
        @data = @line
        classify
      end
    end

    def attr a
      attributes[a]
    end

    def category? category
      categories.include?(category)
    end
    alias_method :cat?, :category?

    def category_color cat, debug = false
      return :black if hidden?
      cmap = {
        s_debug: :black,
        s_config: :cyan,
        s_config_err: :red,
        g_event: :green,
        p_state: :green,
        g_hibernation: :magenta,
        p_log: :blue,
        error: :red,
        nil => :red,
      }
      cat.each {|c| return cmap[c] if cmap[c] }
      :magenta
    end

    def colored_category debug = false
      return ["[UNCLASSIFIED] ".rjust(20, " "), :red] unless classified?
      return ["[#{categories.first.to_s.upcase}] ".rjust(20, " "), category_color(categories, debug)]
    end

    def classified?
      @classified
    end

    def hidden?
      @hidden
    end

    def draw app, out
      out << [["[DEBUG-LI] ", :black], ["#{@line}", :yellow]] if app.opts[:debug]
      if @custom_draw.respond_to?(:call)
        @custom_draw.call(out, format_time(@time), colored_category(app.opts[:debug]))
      else
        out << [
          format_time(@time),
          colored_category(app.opts[:debug]),
          ["#{@data}", @data_color],
        ]
      end
      out << [["".rjust(29, " "), :yellow], ["#{attributes.inspect}", :black]] if attributes.any? && (app.opts[:debug] || app.opts[:show_attributes])
    end

    def classify
      return unless @data.is_a?(String)

      %w[
        random_shit
        gungame
        mapchange
        mapvote
        game_events
        server_config
        player_actions
        bullshit_cvars
        metamod
      ].detect {|m| __send__(:"classify_#{m}") ; classified? }
    end
  end
end

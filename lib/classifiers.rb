module SrcdsLog
  class Line
    module Classifiers
      def classify_metamod
        if m = @data.match(/\A\[META\] Loaded ([0-9]+) plugins \(([0-9]+) already loaded\)\z/)
          @classified = true
          @hidden = true
          @categories << :metamod << :plugin_load
          @data = @data[7..-1]
          @attributes[:loaded] = m[1]
          @attributes[:already_loaded] = m[2]
        end
      end

      def classify_gungame
        # GG debug
        if @data.start_with?("[gungame.smx] [DEBUG-GUNGAME]")
          @classified = true
          @hidden = true
          @categories << :gungame_debug << :gungame << :debug
          @data = @data[14..-1]
        end

        if @data.start_with?("[GunGame]")
          @classified = true
          @hidden = true
          @categories << :gungame
          @data = @data[10..-1]

          if @data.end_with?("Loading gungame.config.txt config file", "Loading gungame.equip.txt config file")
            @categories.unshift :gungame_cfg
          end
        end
      end

      def classify_random_shit
        # dunno what that is
        if @data == "EVERYONE CAN BUY!"
          @classified = true
          @categories << :s_debug << :debug
          @hidden = true
        end

        # some random error, I don't care and neither should you unless you wanna fix them
        if [
          @data.end_with?("has no target."),
          @data == "Error parsing BotProfile.db - unknown attribute 'Rank'",
          @data == "CSoundEmitterSystemBase::GetParametersForSound:  No such sound Error",
          @data.match(/\AConVarRef ([^\s]+) doesn't point to an existing ConVar\z/),
          @data.match(/\ACommentary: Could not find commentary data file 'maps\/(.*)\.txt'\.\z/),
          @data.match(/\ABad SetLocalAngles\(.*\) on InstanceAuto2-fanblade1\z/),
          @data.match(/\ACSoundEmitterSystemBase::GetParametersForSound:  No such sound (.+)\z/),
          @data.match(/\ACHostage::Precache: missing hostage models for map ([^\.]+)\. Adding the default models\.\z/),
          @data.match(/\A\[STEAM_([^\]]+)\] Pure server: file: ([^\s]+) \(([^\)]+)\) could not open file to hash \( benign for now \) : ([a-z0-9]+) :\z/),
          @data.match(/\AGameTypes: missing mapgroupsSP entry for game type\/mode \(([^\)]+)\)\.\z/),
          @data.match(/\ACSceneEntity::GenerateSceneForSound:  Couldn't determine duration of (.*)\z/),
          @data.match(/\AInvalid map '(.*)' included in map cycle file\. Ignored\.\z/),
        ].any?{|t| t}
          @classified = true
          @categories << :s_debug << :debug << :debug_error
          @hidden = true
        end

        # some random info messages no one cares about
        if [
          @data == "Error log file session closed.",
          @data == "Game will not start until both teams have players.",
          @data.match(/\AMolotov projectile spawned at ([0-9\-\.]+) ([0-9\-\.]+) ([0-9\-\.]+), velocity ([0-9\-\.]+) ([0-9\-\.]+) ([0-9\-\.]+)\z/),
        ].any?{|t| t}
          @classified = true
          @categories << :s_debug << :debug << :debug_info
          @hidden = true
        end

        # stringtables... ?!?
        if [
          @data == "#######################################",
          @data.match(/\AMap ([^\s]+) missing stringtable dictionary, don't ship this way!!!\z/),
          @data == "Run with -stringtables on the command line or convar",
          @data == "stringtable_alwaysrebuilddictionaries enabled to build the string table",
        ].any?{|t| t}
          @classified = true
          @categories << :s_debug << :debug << :debug_info
          @hidden = true
        end

        # reservation cookies... cookies? did someone say cookies? ._. ^o^
        if m = @data.match(/\A-> Reservation cookie ([0-9]+):  reason reserved\((yes|no)\), clients\((yes|no)\), reservationexpires\(([0-9\.]+)\)\z/)
          @classified = true
          @hidden = true
          @categories << :s_hibernation << :s_config
          @attributes[:cnum] = m[1].to_i
          @attributes[:reserved] = strbool(m[2])
          @attributes[:clients] = strbool(m[3])
          @attributes[:expires] = m[4].to_f
        end

        if m = @data.match(/\A-> Reservation cookie ([a-z0-9]+):  reason (.*)\z/)
          @classified = true
          @hidden = true
          @categories << :s_hibernation << :s_config
          @attributes[:chash] = m[1]
          @attributes[:reason] = m[2]
        end

        # worker stuff
        if m = @data.match(/\A(?:Stopping|Starting) ([0-9]+) worker threads\z/)
          @classified = true
          @hidden = true
          @categories << :s_core
          @attributes[:tnum] = m[1].to_i
        end
        if m = @data.match(/\A([0-9]+) threads. ([0-9,]+) ticks\z/)
          @classified = true
          @hidden = true
          @categories << :s_core
          @attributes[:tnum] = m[1].to_i
          @attributes[:ticks] = m[2].gsub(",", "").to_i
        end
      end

      def classify_mapvote
        if m = @data.match(/\A\[mapchooser\.smx\] Voting for next map has started\.\z/)
          @classified = true
          @categories << :mapvote << :sourcemod
        end

        if m = @data.match(/\A\[mapchooser\.smx\] Voting for next map has finished\. Nextmap: (.+)\.\z/)
          @classified = true
          @categories << :mapvote << :sourcemod
          @attributes[:nextmap] = m[1]
        end
      end

      def classify_mapchange
        if @data == "Going to intermission..."
          @classified = true
          @categories << :mapchange << :intermission
          @hidden = true
        end

        if m = @data.match(/\ACHANGELEVEL: Looking for next level in mapgroup '([^']+)?'\z/)
          @classified = true
          @categories << :mapchange << :s_mgroup
          @hidden = true
          @attributes[:mapgroup] = m[1]
        end

        if m = @data.match(/\ALooking for next map in mapgroup '([^']+)?'...\z/)
          @classified = true
          @categories << :mapchange << :s_mgroup
          @hidden = true
          @attributes[:mapgroup] = m[1]
        end

        if m = @data.match(/\ACHANGELEVEL: GetNextMap failed for mapgroup '([^']+)?', map group invalid or empty\z/)
          @classified = true
          @categories << :mapchange << :s_mgroup << :error
          @hidden = true
          @attributes[:mapgroup] = m[1]
        end

        if m = @data.match(/\ACHANGE LEVEL: (.+)\z/)
          @classified = true
          @categories << :mapchange << :s_clevel
          @hidden = true
          @attributes[:map] = m[1]
        end

        if m = @data.match(/\A---- Host_Changelevel ----\z/i)
          @classified = true
          @categories << :mapchange << :s_clevel
        end

        if m = @data.match(/\A-------- Mapchange to (.*) --------\z/i)
          @classified = true
          @categories << :mapchange
          @attributes[:map] = m[1]
        end

        if m = @data.match(/\A\[SM\] Changed map to "([^"]+)"\z/i)
          @classified = true
          @categories << :mapchange << :sourcemod
          @attributes[:map] = m[1]
        end

        if m = @data.match(/\ALoading map "([^"]+)"\z/i)
          @classified = true
          @categories << :mapchange << :loading
          @attributes[:map] = m[1]
        end

        if m = @data.match(/\AStarted map "([^"]+)" \(CRC "([^"]+)"\)\z/i)
          @classified = true
          @categories << :mapchange << :loading
          @attributes[:map] = m[1]
          @attributes[:crc] = m[2]
        end
      end

      def classify_server_config
        # config execution
        if @data == "Executing dedicated server config file"
          @classified = true
          @categories << :s_config << :info
        end

        # invalid commands
        if m = @data.match(/\AUnknown command "([^"]+)"\z/)
          @classified = true
          @data_color = :red
          @categories << :s_config_err << :s_config << :error
          @attributes[:invalid_command] = m[1]
        end

        # random spawnpoint generation
        if m = @data.match(/\AGiving up attempts to make more random spawn points\. Current count: ([0-9]+)\.\z/i)
          @classified = true
          @categories << :s_config << :s_spawns << :info
          @attributes[:spawnpoints] = m[1].to_i
        end

        # random hostage position selection
        if m = @data.match(/\ASelected ([0-9]+) hostage positions '([^']+)'\z/i)
          @classified = true
          @categories << :s_config << :s_spawns << :s_hostages << :info
          @attributes[:hostages] = m[1].to_i
          @attributes[:positions] = m[2].to_s.split(",").map(&:to_i)
          @hidden = true
        end

        # server cvar
        if m = @data.match(/\Aserver_cvar: "([^"]+)" "([^"]+)?"\z/i)
          @classified = true
          @categories << :s_cvar << :s_config << :info
          @attributes[:cvar] = m[1]
          @attributes[:value] = m[2]
          @hidden = true
        end

        # server cvar hint
        if @data == "server cvars start" || @data == "server cvars end"
          @classified = true
          @categories << :s_cvar << :s_config << :info << :z_marker
          @hidden = true
          @data_color = :cyan
        end

        # logging
        if m = @data.match(/\AServer logging data to file (logs\/(?:.*)\.log)\z/i)
          @classified = true
          @categories << :s_log << :s_config << :info
          @attributes[:logfile] = m[1]
          @hidden = true
        end

        # logging2
        if m = @data.match(/\ALog file started \(file "(logs\/(?:.*)\.log)"\) \(game \"(.*)"\) \(version "([0-9]+)"\)\z/)
          @classified = true
          @data_color = :blue
          @categories << :s_log << :s_config << :info
          @attributes[:logfile] = m[1]
          @attributes[:gamedir] = m[2]
          @attributes[:version] = m[3].to_i
        end

        # writing bann files
        if m = @data.match(/\AWriting (cfg\/banned_(?:user|ip)\.cfg).\z/)
          @classified = true
          @hidden = true
          @categories << :s_config << :info
          @attributes[:file] = m[1]
        end
      end

      def classify_game_events
        # event triggers
        if m = @data.match(/\A(.+) triggered "([^"]+)"( on "(.*)")?\z/)
          tb = m[1]
          tb = tb[1..-2] if tb.start_with?('"') && tb.end_with?('"')
          @classified = true
          @categories.unshift(:g_event)
          @attributes[:triggered_by] = tb
          @attributes[:event] = m[2].to_s.downcase
          @attributes[:map] = m[3] if m[3]
          @data_color = :magenta

          if @attributes[:event].start_with?("gg_")
            @categories.unshift(:gungame, :gg_event)
            @data_color = :cyan
          end

          if m2 = tb.match(/\A#{RE_NTAG_WT}\z/)
            @data_color = :cyan
            @attributes[:player] = m2[1]
            @attributes[:level] = m2[2].to_i
            @attributes[:bot] = m2[3] == "BOT"
            @attributes[:steam_id] = m2[3] unless m2[3] == "BOT"
            @attributes[:team] = m2[4]
          end
        end

        # team scored
        if m = @data.match(/\ATeam "([^"]+)" scored "([0-9]+)" with "([0-9]+)" players\z/)
          @classified = true
          @categories << :g_score << :g_event
          @attributes[:team] = m[1]
          @attributes[:score] = m[2].to_i
          @attributes[:players] = m[3].to_i
        end

        # team tag change
        if m = @data.match(/\ATeam playing "([^"]+)": (.*)\z/)
          @classified = true
          @data_color = :cyan
          @categories << :g_event << :g_team << :g_tagchange
          @attributes[:team] = m[1]
          @attributes[:tag] = m[2]
        end

        # hibernation start
        if @data == "Server is hibernating"
          @classified = true
          @data_color = :red
          @categories << :g_hibernation << :g_event
        end

        # hibernation end
        if @data == "Server waking up from hibernation"
          @classified = true
          @data_color = :green
          @categories << :g_hibernation << :g_event
        end
      end

      def classify_player_actions
        # client connect
        if m = @data.match(/\AClient "(.*)" connected \((#{RE_IPV4}):([0-9]+)\).\z/)
          @classified = true
          @categories << :p_state << :p_connected << :p_log
          @attributes[:player] = m[1]
          @attributes[:ip] = m[2]
          @attributes[:port] = m[3].to_i
          @data_color = :green
          return
        end

        # client disconnect
        if m = @data.match(/\ADropped (.*) from server: (.*)\z/)
          @classified = true
          @categories << :p_state << :p_disconnected << :p_log
          @attributes[:player] = m[1]
          @attributes[:reason] = m[2]
          @data_color = :red
        end

        # killfeed
        if m = @data.match(/\A"#{RE_NTAG_WT}" #{RE_COORD} killed "#{RE_NTAG_WT}" #{RE_COORD} with "([^"]+)"( \([a-z\s]+\))?\z/i)
          @classified = true
          @data_color = :cyan
          @categories << :killfeed << :p_log
          cdm = m # presever match data for custom draw
          @custom_draw = ->(out, time, cat) do
            hs = "🔫 " if cdm[16] && cdm[16]["headshot"]
            wb = "🎯 " if cdm[16] && cdm[16]["penetrated"]
            out << [
              time, cat,
              ["💀 #{hs}#{wb} ", :yellow],
              ["#{cdm[1]}", :red],
              [" killed ", :yellow],
              ["#{cdm[8]}", :red],
              [" with ", :yellow],
              ["#{cdm[15]}", :blue],
            ]
          end
          @data = "#{m[1]} => #{m[8]} with #{m[15]}"

          @attributes[:weapon] = m[15]
          @attributes[:headshot] = m[16] && m[16]["headshot"]
          @attributes[:wallbang] = m[16] && m[16]["penetrated"]
          @attributes[:bot] = m[3] == "BOT" && m[10] == "BOT"
          @attributes[:killer] = m[1]
          @attributes[:killer_level] = m[2]
          @attributes[:killer_bot] = m[3] == "BOT"
          @attributes[:killer_steam_id] = m[3] unless m[3] == "BOT"
          @attributes[:killer_team] = m[4]
          @attributes[:killer_pos] = [m[5].to_i, m[6].to_i, m[7.to_i]]

          @attributes[:victim] = m[8]
          @attributes[:victim_level] = m[9]
          @attributes[:victim_bot] = m[10] == "BOT"
          @attributes[:victim_steam_id] = m[10] unless m[10] == "BOT"
          @attributes[:victim_team] = m[11]
          @attributes[:victim_pos] = [m[12].to_i, m[13].to_i, m[14.to_i]]
          return # we changed @data but otherwise with team actions would match BS
        end

        # with team actions
        if m = @data.match(/\A"#{RE_NTAG_WT}"(.*)\z/i)
          @classified = true
          @categories << :p_log
          @attributes[:player] = m[1]
          @attributes[:level] = m[2].to_i
          @attributes[:bot] = m[3] == "BOT"
          @attributes[:steam_id] = m[3] unless m[3] == "BOT"
          @attributes[:team] = m[4]
          @attributes[:message] = m[5].to_s.strip
          if @attributes[:message].include?("connected, address")
            @data_color = :green
            @categories.unshift(:p_state, :p_connected)
          end
          @categories.unshift(:p_state, :p_entered_game) if @attributes[:message] == "entered the game"

          # clantag assignment
          if m2 = @attributes[:message].match(/\Atriggered "clantag" \(value "(.*)"\)\z/)
            @categories.unshift(:p_state, :p_changed_clantag)
            @attributes[:clantag] = m2[1]
            @data_color = :blue
          end

          # STEAM USERID validated
          if @attributes[:message] == "STEAM USERID validated"
            @categories.unshift(:p_state, :p_steamid_validated)
          end

          # disconnect
          if m2 = @attributes[:message].match(/\Adisconnected \(reason "(.*)"\)\z/)
            @categories.unshift(:p_state, :p_disconnected)
            @attributes[:reason] = m2[1]
            @data_color = :red
          end
        end

        # Teamless actions
        if m = @data.match(/\A"(.+)<([0-9]+)><(BOT|STEAM_[0-9:]+)>"(.*)\z/i)
          @classified = true
          @categories << :p_log
          @attributes[:player] = m[1]
          @attributes[:level] = m[2].to_i
          @attributes[:bot] = m[3] == "BOT"
          @attributes[:steam_id] = m[3] unless m[3] == "BOT"
          @attributes[:message] = m[4].to_s.strip

          # team switch
          if m2 = @attributes[:message].match(/\Aswitched from team <([^>]+)> to <([^>]+)>\z/)
            @categories.unshift(:p_state, :p_changed_team)
            @attributes[:team_was] = m2[1].downcase
            @attributes[:team_new] = m2[2].downcase
            @data_color = :blue
          end
        end
      end

      def classify_bullshit_cvars
        if m = @data.match(/\A"?((?:mp_|sv_|spec_|bot_|cash_|ff_|r_|csg_|tv_|sm_|weapon_)[^\s"]+)"? (?:(?:-(?: (.*))?)|(?:= "?([^"]+)?"?))\z/)
          @hidden = true
          @classified = true
          @categories << :s_cvar_bs
          @attributes[:cvar] = m[1]
          @attributes[:value] = m[2] || m[3]
        end

        # catch custom stuff only for quote version
        if m = @data.match(/\A"([^\s"]+)" = "([^"]+)?"\z/)
          @hidden = true
          @classified = true
          @categories << :s_cvar_bs
          @attributes[:cvar] = m[1]
          @attributes[:value] = m[2]
        end
      end
    end
  end
end

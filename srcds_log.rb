#!/usr/bin/env ruby

APP_ROOT = File.expand_path(File.dirname(__FILE__))
require "#{APP_ROOT}/lib/dependencies"
STDOUT.sync = true

module SrcdsLog
  VERSION = "1.0.0"
  UPDATE_URL = "https://gist.githubusercontent.com/2called-chaos/bd1daaaac4255ac8028a30a74b749402/raw/srcds_log.rb"
end

begin
  app = SrcdsLog::Application.new(ENV, ARGV, ARGF)
  app.dispatch do |rec|
    # load feeds from directory, do not remove this :-)
    Dir["#{APP_ROOT}/feeds/*.rb"].each do |f|
      next if File.basename(f).start_with?("__")
      eval(File.read(f))
    end

    # Filter your records here!
    # Feeds are passed via -f or --feeds option (ordered)
    # If the block returns a truthy value it will be drawn.
    # You can organize your feeds in the ./feeds directory!
    app.feed :my_feed, desc: "My personal config" do
      # skip hidden messages (boring stuff is hidden)
      # (don't return or break cause it will fuck up, use throw instead)
      throw :next if $rec.hidden?

      # skip bot messages
      throw :next if $rec.attr(:bot)

      puts "---------------------------------------"
      puts app.c("   $rec methods: ", :yellow) << (($rec.methods - Object.methods).reject{|m| m.to_s.start_with?("classify_") }).inspect
      puts app.c("$rec categories: ", :yellow) << $rec.categories.inspect
      puts app.c("$rec attributes: ", :yellow) << $rec.attributes.inspect

      # you "could" use colors (see colorize.rb for colors)
      puts app.c("UNCLASSIFIED! :o", :red) if !$rec.classified?


      # The result of the block will determine whether the
      # message will be drawn/shown or not. false or nil
      # will hide the message.
      true
    end

    # if no feed is given this will be the default filter
    app.default do
      [
        !$rec.hidden? || app.opts[:show_hidden],
      ].all?{|v| v }
    end
  end
rescue Errno::EPIPE
  exit(74)
end

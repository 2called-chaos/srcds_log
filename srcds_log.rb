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
    # Filter your records here!
    # If the block returns a truthy value it will be drawn

    # feeds are passed via -f or --feeds option (ordered)
    app.feed :join do
      (!$rec.hidden? || app.opts[:show_hidden]) && $rec.categories.include?(:p_connected)
    end

    app.feed :leave do
      (!$rec.hidden? || app.opts[:show_hidden]) && $rec.categories.include?(:p_disconnected)
    end

    app.feed(:jl) { app.feeds[:join].call || app.feeds[:leave].call }

    app.feed :unclassified do
      !$rec.classified?
    end

    app.feed :bot do
      $rec.attributes[:bot]
    end

    app.feed :nobot do
      !app.feeds[:bot].call
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

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

app.feed(:silent, desc: "don't show anything") { false }

app.feed(:hidden, desc: "include hidden") { $rec.hidden? }
app.feed(:visible, desc: "exclude hidden") { !$rec.hidden? || app.opts[:show_hidden] }

app.feed(:join, desc: "join/connect messages") { $rec.cat?(:p_connected) }
app.feed(:leave, desc: "disconnect messages") { $rec.cat?(:p_disconnected) }
app.feed(:jl, :join_leave, desc: "(dis)connect messages") { app.feeds[:join].call || app.feeds[:leave].call }

app.feed(:kf, :killfeed, desc: "all kills") { $rec.cat?(:killfeed) }

app.feed(:classified, desc: "include classified") { $rec.classified? }
app.feed(:unclassified, desc: "exclude classified") { !$rec.classified? }

app.feed(:bot, desc: "include bot only") { $rec.attributes[:bot] }
app.feed(:nobot, desc: "exclude bot only") { !$rec.attributes[:bot] }

app.feed(:interesting, desc: "author recommended") do
  bot = $rec.attr(:bot)
  [
    !$rec.classified?,
    $rec.cat?(:killfeed) && !bot,
    $rec.cat_any?(:mapvote, :s_clevel),
    !bot && app.feeds[:jl].call,
  ].any?{|v| v}
end

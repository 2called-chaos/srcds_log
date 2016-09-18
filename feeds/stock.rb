app.feed(:silent, desc: "don't show anything") { false }

app.feed(:hidden, desc: "include hidden") { $rec.hidden? }
app.feed(:visible, desc: "exclude hidden") { !$rec.hidden? || app.opts[:show_hidden] }

app.feed(:join, desc: "join/connect messages") { $rec.categories.include?(:p_connected) }
app.feed(:leave, desc: "disconnect messages") { $rec.categories.include?(:p_disconnected) }
app.feed(:jl, desc: "(dis)connect messages") { app.feeds[:join].call || app.feeds[:leave].call }

app.feed(:classified, desc: "include classified") { $rec.classified? }
app.feed(:unclassified, desc: "exclude classified") { !$rec.classified? }

app.feed(:bot, desc: "include bot only") { $rec.attributes[:bot] }
app.feed(:nobot, desc: "exclude bot only") { !$rec.attributes[:bot] }

app.feed(:interesting, desc: "author recommended") do
  !$rec.classified? || ($rec.cat?(:killfeed) && !$rec.bot) || app.feeds[:jl].call
end

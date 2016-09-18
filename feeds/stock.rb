app.feed(:hidden) { $rec.hidden? }
app.feed(:visible) { !$rec.hidden? || app.opts[:show_hidden] }

app.feed(:join) { $rec.categories.include?(:p_connected) }
app.feed(:leave) { $rec.categories.include?(:p_disconnected) }
app.feed(:jl) { app.feeds[:join].call || app.feeds[:leave].call }

app.feed(:classified) { $rec.classified? }
app.feed(:unclassified) { !$rec.classified? }

app.feed(:bot) { $rec.attributes[:bot] }
app.feed(:nobot) { !$rec.attributes[:bot] }

app.feed(:interesting) do
  !$rec.classified? || ($rec.cat?(:killfeed) && !$rec.bot) || app.feeds[:jl].call
end

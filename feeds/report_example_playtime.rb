# users by playtime
users_pt = {}
users_m = {}
app.feed :users_by_playtime do
  # throw :next if $rec.attr(:bot)
  player = "#{"[BOT] " if $rec.attr(:bot)}#{$rec.attr(:player)}"
  throw :next unless $rec.time
  if $rec.categories.include?(:p_connected)
    users_pt[player] ||= [0, 0.0]
    users_pt[player][0] += 1
    users_m[player] = $rec.time
  elsif $rec.categories.include?(:p_disconnected)
    if t = users_m[player]
      users_pt[player] ||= [0, 0.0]
      users_pt[player][1] += $rec.time - t
      users_m[player] = nil
    end
  end
  false # don't draw anything just our stuff (finalizer)
end
app.finalize(:users_by_playtime) do
  sorted = users_pt.sort_by{|name, (connects, playtime)| playtime}.reverse
  puts sorted.map{|name, (connects, playtime)| "#{name} "[0..35].rjust(35, " ") << app.human_seconds(playtime).ljust(20, " ") << " in #{connects} sessions" }
end

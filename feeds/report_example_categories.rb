categories = {}
app.feed :list_categories, desc: "list all categories that were assigned in this run" do
  $rec.categories.each do |cat|
    categories[cat] ||= 0
    categories[cat] += 1
  end
  false # don't draw anything just our stuff
end
app.finalize(:list_categories) { puts categories.sort_by{|c, i| i}.reverse.map{|c, i| "#{i}\t#{c}" } }

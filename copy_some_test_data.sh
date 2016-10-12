target_dir="../ofis-slush-new-json/test/data"
mkdir -p $target_dir
#ls ../ofis-slush-new-json/1/data/ |sed 's/\(.*\)/grep -inH match-count\\":2 ..\/ofis-slush-new-json\/1\/data\/&/g' |head -1000|sh|sed 's/\(.*\).json:.*/\1.json/g'|xargs -I{} cp {} $target_dir
#ls ../ofis-slush-new-json/2/data/ |sed 's/\(.*\)/grep -inH match-count\\":2 ..\/ofis-slush-new-json\/2\/data\/&/g' |head -1000|sh|sed 's/\(.*\).json:.*/\1.json/g'|xargs -I{} cp {} $target_dir
grep match-count\":2 out3|sed 's/\(.*\){\(.*\)/\1/g'

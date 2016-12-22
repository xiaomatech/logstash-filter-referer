# logstash-filter-referer

#build
gem build logstash-filter-referer.gemspec

#install 
/usr/share/logstash/bin/logstash-plugin install --no-verify logstash/plugin/logstash-filter-referer-1.0.0.gem

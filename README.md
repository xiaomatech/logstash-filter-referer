# logstash-filter-referer

#build
```
gem build logstash-filter-referer.gemspec
```
#install 
```
ln -s /usr/share/logstash/vendor/jruby/bin/jruby /usr/sbin/jruby
/usr/share/logstash/vendor/jruby/bin/gem install referer-parser-0.3.0.gem
/usr/share/logstash/bin/logstash-plugin install --no-verify logstash/plugin/logstash-filter-referer-1.0.0.gem

```


## 例子
```ruby
filter {
     referer {
       source => "http_referer"
       target => "referer"
       referers_file => "/etc/logstash/conf.d/referer.yaml"
     }
}
```

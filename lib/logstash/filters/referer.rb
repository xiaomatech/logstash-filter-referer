# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "lru_redux"
require "tempfile"
require "thread"

class LogStash::Filters::Referer < LogStash::Filters::Base
  LOOKUP_CACHE = LruRedux::ThreadSafeCache.new(10000)

  config_name "referer"

  config :source, :validate => :string, :required => true

  config :target, :validate => :string, :default => 'referer'

  config :referers_file, :validate => :string,:default => '/etc/logstash/conf.d/referer.yaml'

  config :lru_cache_size, :validate => :number, :default => 10000

  config :prefix, :validate => :string, :default => ''

  def register
     require 'referer-parser'
     if @referers_file.nil?
        begin
          @parser = RefererParser::Referer.new('http://logstash.net')
        rescue Exception => e
          begin
            if __FILE__ =~ /file:\/.*\.jar!/
              # Running from a flatjar which has a different layout
              referers_file = [__FILE__.split("!").first, "/vendor/referer-parser/data/referers.yaml"].join("!")
              @parser = RefererParser::Referer.new('http://logstash.net', referers_file)
            else
              # assume operating from the git checkout
              @parser = RefererParser::Referer.new('http://logstash.net', "vendor/referers_file/referers.yaml")
            end
          rescue => ex
            raise "Failed to cache, due to: #{ex}\n#{ex.backtrace}"
          end
        end
    else
        @logger.info("Using referer-parser with external referers.yml", :referers_file => @referers_file)
        @parser = RefererParser::Referer.new('http://logstash.net', @referers_file)
    end

    LOOKUP_CACHE.max_size = @lru_cache_size

    normalized_target = (@target && @target !~ /^\[[^\[\]]+\]$/) ? "[#{@target}]" : ""

    @prefixed_known = "#{normalized_target}[#{@prefix}known]"
    @prefixed_host = "#{normalized_target}[#{@prefix}host]"
    @prefixed_name = "#{normalized_target}[#{@prefix}name]"
    @prefixed_search_term = "#{normalized_target}[#{@prefix}search_term]"

  end #def register

  def filter(event)
    referer = event.get(@source)
    referer = referer.first if referer.is_a?(Array)

    return if referer.nil? || referer.empty?

    begin
      referer_data = lookup_referer(referer)
    rescue StandardError => e
      @logger.error("Uknown error while parsing referer data", :exception => e, :field => @source, :event => event)
      return
    end

    return unless referer_data

    event.remove(@source) if @target == @source

    set_fields(event, referer_data)

    filter_matched(event)
  end

  def lookup_referer(referer)
    return unless referer

    cached = LOOKUP_CACHE[referer]
    return cached if cached

    referer_data = nil
    referer_data = @parser.parse(referer)

    LOOKUP_CACHE[referer] = referer_data
    referer_data
  end

  private

  def set_fields(event, referer_data)
    if !referer_data.nil?
        event.set(@prefixed_known, referer_data.known.to_s.dup.force_encoding(Encoding::UTF_8)) if referer_data.known
        event.set(@prefixed_name, referer_data.name.to_s.dup.force_encoding(Encoding::UTF_8)) if referer_data.name
        event.set(@prefixed_host, referer_data.host.to_s.dup.force_encoding(Encoding::UTF_8)) if referer_data.host
        event.set(@prefixed_search_term, referer_data.search_term.to_s.dup.force_encoding(Encoding::UTF_8)) if referer_data.search_term
    end
  end

end

# encoding: utf-8

require "logstash/devutils/rspec/spec_helper"
require "logstash/filters/referer"

describe LogStash::Filters::Referer do

  describe "defaults" do
    config <<-CONFIG
      filter {
        referer {
          source => "message"
          target => "referer"
        }
      }
    CONFIG
  end

  describe "Without target field" do
    config <<-CONFIG
      filter {
        referer {
          source => "message"
        }
      }
    CONFIG
  end

  describe "Without referer" do
    config <<-CONFIG
      filter {
        referer {
          source => "message"
          target => "referer"
        }
      }
    CONFIG

    sample "foo" => "bar" do
      reject { subject }.include?("referer")
    end

    sample "" do
      reject { subject }.include?("referer")
    end
  end

  describe "Replace source with target" do
    config <<-CONFIG
      filter {
        referer {
          source => "message"
          target => "message"
        }
      }
    CONFIG
  end
end

$: << '../lib/'
require 'ruby_json_api_client'
require 'oj'
require 'yajl'
require 'benchmark/ips'

json = {
  person: {
    id: 1,
    firstname: 'ryan',
    lastname: 'test',
    links: {
      posts: '/posts?person_id=1'
    }
  }
}.to_json

Benchmark.ips do |x|
  x.report("json serializer") do
    serializer = RubyJsonApiClient::AmsSerializer.new(
      json_parsing_method: JSON.method(:parse)
    )
    serializer.transform(json)
  end

  x.report("oj serializer") do
    serializer = RubyJsonApiClient::AmsSerializer.new(
      json_parsing_method: Oj.method(:load)
    )
    serializer.transform(json)
  end

  x.report("yajl") do
    serializer = RubyJsonApiClient::AmsSerializer.new(
      json_parsing_method: Yajl::Parser.method(:parse)
    )
    serializer.transform(json)
  end
end

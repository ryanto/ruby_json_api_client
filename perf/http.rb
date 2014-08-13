$: << '../lib/'
require 'ruby_json_api_client'
require 'typhoeus/adapters/faraday'
require 'benchmark/ips'
require 'webmock'

include WebMock::API

class Person < RubyJsonApiClient::Base
  field :firstname
  field :lastname
  has_many :items
end

stub_request(:get, "https://www.example.com/perf/people/1")
  .to_return(
    status: 200,
    body: {}.to_json
  )

adapter = RubyJsonApiClient::RestAdapter.new(
  hostname: 'www.example.com',
  secure: true,
  namespace: 'perf'
 )

Benchmark.ips do |x|
  x.report("net http") do
    adapter.http_client = :net_http
    adapter.find(Person, 1)
  end

  x.report("typhoeus") do
    adapter.http_client = :typhoeus
    adapter.find(Person, 1)
  end
end

$: << '../lib/'
require 'ruby_json_api_client'
require 'typhoeus/adapters/faraday'
require 'benchmark/ips'
require 'webmock'

include WebMock::API

adapter_options = {
  hostname: 'www.example.com',
  namespace: 'perf',
  secure: true
}


class Person < RubyJsonApiClient::Base
  field :firstname
  field :lastname
  has_many :items
end

class Item < RubyJsonApiClient::Base
  field :name
end

person_1_response = {
  person: {
    id: 1,
    firstname: 'ryan',
    lastname: 'test',
    links: {
      items: '/perf/items?person_id=1'
    }
  }
}.to_json

stub_request(:get, "https://www.example.com/perf/people/1")
  .to_return(
    status: 200,
    headers: { 'Content-Length' => person_1_response.size },
    body: person_1_response
  )


Benchmark.ips do |x|
  x.report("net_http find") do
    RubyJsonApiClient::Store.register_adapter(
      :ams,
      adapter_options.merge(http_client: :net_http)
    )
    RubyJsonApiClient::Store.register_serializer(:ams)
    RubyJsonApiClient::Store.default(:ams)

    Person.find(1)
  end



  x.report("typhoeus find") do
    RubyJsonApiClient::Store.register_adapter(
      :ams,
      adapter_options.merge(http_client: :typhoeus)
    )
    RubyJsonApiClient::Store.register_serializer(:ams)
    RubyJsonApiClient::Store.default(:ams)

    Person.find(1)
  end
end

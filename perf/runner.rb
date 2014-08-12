$: << '../lib/'
require 'ruby_json_api_client'
require 'benchmark/ips'
require 'webmock'

RubyJsonApiClient::Store.register_adapter(:ams, {
  hostname: 'www.example.com',
  namespace: 'perf',
  secure: true
});

RubyJsonApiClient::Store.register_serializer(:ams)
RubyJsonApiClient::Store.default(:ams)

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

items_for_person_1 = {
  items: [{
    id: 3,
    name: 'test item'
  },{
    id: 4,
    name: 'second test item'
  }]
}.to_json

person_2_response = {
  person: {
    id: 2,
    firstname: 'steve',
    lastname: 'holt'
  },
  items: [{
    id: 3,
    name: 'test item'
  },{
    id: 4,
    name: 'second test item'
  }]
}.to_json

include WebMock::API

stub_request(:get, "https://www.example.com/perf/people/1")
  .to_return(
    status: 200,
    headers: { 'Content-Length' => person_1_response.size },
    body: person_1_response
  )

stub_request(:get, "https://www.example.com/perf/items?person_id=1")
  .to_return(
    status: 200,
    headers: { 'Content-Length' => person_2_response.size },
    body: items_for_person_1
  )

stub_request(:get, "https://www.example.com/perf/people/2")
  .to_return(
    status: 200,
    headers: { 'Content-Length' => person_2_response.size },
    body: person_2_response
  )

Benchmark.ips do |x|
  x.report("find") do
    person = Person.find(1)
    person.firstname == 'ryan'
    person.lastname == 'test'
  end

  x.report("find then many sideloaded relationship") do
    person = Person.find(2)
    items = person.items
    items.size == 2
  end

  x.report("find then links relationship") do
    person = Person.find(1)
    items = person.items
    items.size == 2
  end
end

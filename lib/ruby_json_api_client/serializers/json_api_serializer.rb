require 'json'
require 'active_support'

module RubyJsonApiClient
  class JsonApiSerializer
    attr_accessor :store

    def transform(response)
      JSON.parse(response)
    end

    def assert(test, failure_message)
      raise failure_message if !test
    end

    def _json_to_model(klass, json)
      json.reduce(klass.new) do |model, (field, value)|
        if klass.has_field?(field.to_sym)
          model.send("#{field}=", value)
        end

        model
      end
    end

    def extract_single(klass, id, response)
      name = klass.to_s.underscore
      plural = ActiveSupport::Inflector.pluralize(name)
      data = transform(response)

      assert data[plural],
        "No key #{plural} in json response."

      assert data[plural].is_a?(Array),
        "Key #{plural} should be an array"

      assert data[plural][0]['id'],
        "No id included in #{plural}[0] json data"

      assert data[plural][0]['id'].to_s == id.to_s,
        "Tried to find #{name} with id #{id}, but got #{name} with id #{data[plural][0]['id']}."

      _json_to_model(klass, data[plural][0])
    end

    def extract_many(klass, response)
      name = klass.to_s.underscore
      plural = ActiveSupport::Inflector.pluralize(name)
      data = transform(response)

      assert data[plural],
        "No key #{plural} in json response."

      assert data[plural].is_a?(Array),
        "Key #{plural} should be an array"

      data[plural].reduce([]) do |collection, json|
        collection << _json_to_model(klass, json)
      end
    end

    def extract_many_relationship(parent, name, response)
      # given response this will find the relationship
      # for json api the response will either be
      # 1) in links
      # 2) in linked
      json = transform(response)

      if json['links'] && json['links'][name]
        extract_many_relationship_from_links(name, json['links'][name])

      elsif json['linked'] && json['linked'][name]
        extract_many_relationship_from_linked(name, json['linked'][name])

      else
        raise "You asked for #{name} but it does not exist in links or linked"

      end
    end

    def extract_many_relationship_from_links(name, link)
      link_url = link['href']
      # since we only have a url pointing to where to pull
      # this info from we need to go back to the store and
      # have it pull this data
      store.load_collection(name, link_url)
    end

    def extract_relationship_from_linked(klass, name, linked)
      extract_many(linked)
    end
  end
end

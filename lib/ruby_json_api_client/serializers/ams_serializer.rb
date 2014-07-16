require 'json'
require 'active_support'

module RubyJsonApiClient
  class AmsSerializer
    attr_accessor :store

    def transform(response)
      JSON.parse(response)
    end

    def assert(test, failure_message)
      raise failure_message if !test
    end

    def _create_model(klass, data)
      model = klass.new(meta: {})

      if data['links']
        model.meta[:links] = data['links']
      end

      data.reduce(model) do |record, (field, value)|
        if klass.has_field?(field.to_sym)
          record.send("#{field}=", value)
        end

        record
      end
    end

    def extract_single(klass, id, response)
      name = klass.to_s.underscore
      data = transform(response)

      assert data[name],
        "No key #{name} in json response."

      assert data[name]['id'],
        "No id included in #{name} json data"

      assert data[name]['id'].to_s == id.to_s,
        "Tried to find #{name} with id #{id}, but got #{name} with id #{data[name]['id']}."

      _create_model(klass, data[name])
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
        collection << _create_model(klass, json)
      end
    end

    def extract_many_relationship(parent, name, response)
      # given response this will find the relationship
      # for ams based apis the relationship will either be
      # 1) in links
      # 2) in sideloaded data
      data = transform(response)
      singular = ActiveSupport::Inflector.singularize(name)
      parent_name = parent.class.name.to_s.downcase
      meta = parent.meta || {}
      links = meta[:links]

      if links && links[name.to_s]
        extract_many_relationship_from_links(parent, name, links[name.to_s])

      elsif data[name.to_s] && data[parent_name]["#{singular}_ids"]
        extract_many_relationship_from_sideload(parent, name, response)

      else
        []

      end
    end

    def extract_many_relationship_from_links(parent, name, url)
      # since we only have a url pointing to where to pull
      # this info from we need to go back to the store and
      # have it pull this data
      klass_name = ActiveSupport::Inflector.classify(name)
      klass = ActiveSupport::Inflector.constantize(klass_name)

      store.load_collection(klass, url)
    end

    def extract_relationship_from_sideload(parent, name, response)
      data = transform(response)
      singular = ActiveSupport::Inflector.singularize(name)
      parent_name = parent.class.name.to_s.downcase
      klass_name = ActiveSupport::Inflector.classify(name)
      klass = ActiveSupport::Inflector.constantize(klass_name)

      ids = data[parent_name]["#{singular}_ids"]
      idMap = ids.reduce({}) do |map, id|
        map[id] = true
        map
      end

      extract_many(klass, response)
        .select { |record| idMap[record.id] }
    end
  end
end

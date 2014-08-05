require 'json'
require 'active_support'

module RubyJsonApiClient
  class AmsSerializer
    attr_accessor :store

    def transform(response)
      JSON.parse(response)
    end

    def to_json(model)
      key = model.class.to_s.underscore.downcase
      data = {}
      data[key] = {}

      if model.persisted?
        data[key][:id] = model.id
      end

      # conert fields to json
      model.class.fields.reduce(data[key]) do |result, field|
        result[field] = model.send(field)
        result
      end

      # convert has one relationships to json
      relationships = model.loaded_has_ones || {}
      relationships.reduce(data[key]) do |result, (name, relationship)|
        if relationship.id
          result["#{name}_id"] = relationship.id
        end
        result
      end

      JSON::generate(data)
    end

    def assert(test, failure_message)
      raise failure_message if !test
    end

    def _create_model(klass, data)
      model = klass.new(meta: {})

      model.meta[:data] = data

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

      if id
        # we will allow idless loading, but if an id is given we
        # will try to verify it.
        assert data[name]['id'].to_s == id.to_s,
          "Tried to find #{name} with id #{id}, but got #{name} with id #{data[name]['id']}."
      end

      _create_model(klass, data[name])
    end

    def extract_many(klass, response, key = nil)
      key = klass.to_s.underscore if key.nil?
      plural = ActiveSupport::Inflector.pluralize(key)

      data = transform(response)

      assert data[plural],
        "No key #{plural} in json response."

      assert data[plural].is_a?(Array),
        "Key #{plural} should be an array"

      data[plural].reduce([]) do |collection, json|
        collection << _create_model(klass, json)
      end
    end

    def extract_many_relationship(parent, name, options, response)
      # given response this will find the relationship
      # for ams based apis the relationship will either be
      # 1) in links
      # 2) in sideloaded data
      data = transform(response)
      singular = ActiveSupport::Inflector.singularize(name)
      meta = parent.meta || {}
      meta_links = meta[:links]
      meta_data = meta[:data]

      if meta_links && meta_links[name.to_s]
        extract_many_relationship_from_links(parent, name, options, meta_links[name.to_s])

      elsif data[name.to_s] && meta_data && meta_data["#{singular}_ids"]
        extract_many_relationship_from_sideload(parent, name, options, response)

      else
        []

      end
    end

    def extract_many_relationship_from_links(parent, name, options, url)
      # since we only have a url pointing to where to pull
      # this info from we need to go back to the store and
      # have it pull this data
      klass_name = options[:class_name] || ActiveSupport::Inflector.classify(name)
      klass = ActiveSupport::Inflector.constantize(klass_name)

      store.load_collection(klass, url)
    end

    def extract_many_relationship_from_sideload(parent, name, options, response)
      singular = ActiveSupport::Inflector.singularize(name)
      plural = ActiveSupport::Inflector.pluralize(name)
      klass_name = options[:class_name] || ActiveSupport::Inflector.classify(name)
      klass = ActiveSupport::Inflector.constantize(klass_name)
      meta_data = parent.meta[:data]

      ids = meta_data["#{singular}_ids"]
      idMap = ids.reduce({}) do |map, id|
        map[id] = true
        map
      end

      extract_many(klass, response, plural)
        .select { |record| idMap[record.id] }
    end

    def extract_single_relationship(parent, name, options, response)
      plural = ActiveSupport::Inflector.pluralize(name)
      data = transform(response)
      meta = parent.meta || {}
      meta_links = meta[:links]
      meta_data = meta[:data]

      if meta_links && meta_links[name.to_s]
        extract_single_relationship_from_links(parent, name, options, meta_links[name.to_s])

      elsif data[plural.to_s] && meta_data && meta_data["#{name}_id"]
        extract_single_relationship_from_sideload(parent, name, options, response)

      else
        nil # nothing found, return nil object

      end
    end

    def extract_single_relationship_from_links(parent, name, options, url)
      klass_name = options[:class_name] || ActiveSupport::Inflector.classify(name)
      klass = ActiveSupport::Inflector.constantize(klass_name)
      meta = parent.meta || {}
      meta_data = meta[:data] || {}

      store.load_single(klass, meta_data["#{name}_id"], url)
    end

    def extract_single_relationship_from_sideload(parent, name, options, response)
      plural = ActiveSupport::Inflector.pluralize(name)
      klass_name = options[:class_name] || ActiveSupport::Inflector.classify(name)
      klass = ActiveSupport::Inflector.constantize(klass_name)
      meta_data = parent.meta[:data]
      id = meta_data["#{name}_id"]

      extract_many(klass, response, plural)
        .detect { |record| record.id == id }
    end
  end
end

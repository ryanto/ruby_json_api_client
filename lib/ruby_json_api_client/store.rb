require 'spec_helper'

module RubyJsonApiClient
  class Store
    def self.register_adapter(name, klass = nil, options = {})
      @adapters ||= {}

      # allow for 2 arguments (automatically figure out class if so)
      if !klass.is_a?(Class)
        # klass is options. autoamtically figure out klass and set options
        temp = klass || options
        class_name = name.to_s.camelize
        klass = Kernel.const_get("RubyJsonApiClient::#{class_name}Adapter")
        options = temp
      end

      @adapters[name] = OpenStruct.new({ klass: klass, options: options })
    end


    def self.register_serializer(name, klass = nil)
      @serializers ||= {}

      if klass.nil?
        class_name = name.to_s.camelize
        klass = Kernel.const_get("RubyJsonApiClient::#{class_name}Serializer")
      end

      @serializers[name] = OpenStruct.new({ klass: klass })
    end

    def self.get_serializer(name)
      @serializers ||= {}
      if @serializers[name]
        @serializers[name].klass.new
      end
    end

    def self.get_adapter(name)
      @adapters ||= {}
      if @adapters[name]
        @adapters[name].klass.new(@adapters[name].options)
      end
    end

    def self.default(format)
      @store = new(format: format)
    end

    def self.instance
      @store
    end

    attr_accessor :default_adapter
    attr_accessor :default_serializer

    def initialize(options)
      if options[:format]
        options[:adapter] = options[:format]
        options[:serializer] = options[:format]
      end

      @default_adapter = self.class.get_adapter(options[:adapter])
      @default_serializer = self.class.get_serializer(options[:serializer])

      if @default_serializer && @default_serializer.respond_to?(:store=)
        @default_serializer.store = self
      end
    end

    def adapter_for_class(klass)
      @default_adapter
    end

    def serializer_for_class(klass)
      @default_serializer
    end

    def find(klass, id)
      adapter = adapter_for_class(klass)
      serializer = serializer_for_class(klass)

      response = adapter.find(klass, id)
      serializer.extract_single(klass, id, response).tap do |model|
        model.__origin__ = response
      end
    end

    def query(klass, params)
      adapter = adapter_for_class(klass)
      serializer = serializer_for_class(klass)

      response = adapter.find_many(klass, params)
      list = serializer.extract_many(klass, response)

      list.each do |model|
        # let the model know where it came from
        model.__origin__ = response
      end

      # cant tap proxy
      collection = RubyJsonApiClient::Collection.new(list)
      collection.__origin__ = response
      collection
    end

    def find_many_relationship(parent, name)
      # needs to use adapter_for_class
      serializer = @default_serializer

      # ensure parent is loaded
      if parent.__origin__.nil?
        # load this result into parent
        # need ability to hydrate
        parent.reload
        find(parent.class, parent.id)
      end

      response = parent.__origin__

      # find the relationship
      list = serializer.extract_many_relationship(parent, name, response)

      # wrap in enumerable proxy to allow reloading
      collection = RubyJsonApiClient::Collection.new(list)
      collection.__origin__ = response
      collection
    end

    def find_one_relationship(name, parent)

    end

    def load_collection(klass, url)
      adapter = adapter_for_class(klass)
      serializer = serializer_for_class(klass)
      response = adapter.get(url)
      serializer.extract_many(klass, response)
    end

    def load_single(klass, url)
      adapter = adapter_for_class(klass)
      serializer = serializer_for_class(klass)
      response = adapter.get(url)
      serializer.extract_single(response)
    end

    def load(klass, data)

    end

    def reload(model)
      new_model = find(model.class, model.id)
      merge(model, new_model)
    end

    def merge(into, from)
      # i think the serializer should deceide how to merge
      from.class.fields.reduce(into) do |model, attr|
        call = "#{attr}="
        model.send(call, from.send(attr)) if model.respond_to?(call)
        model
      end
    end

  end
end

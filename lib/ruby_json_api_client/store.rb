module RubyJsonApiClient
  class Store
    def self.register_adapter(name, klass = nil, options = {})
      @adapters ||= {}

      # allow for 2 arguments (automatically figure out class if so)
      if !klass.is_a?(Class)
        # klass is options. autoamtically figure out klass and set options
        temp = klass || options
        class_name = name.to_s.camelize
        klass = "RubyJsonApiClient::#{class_name}Adapter".constantize
        options = temp
      end

      @adapters[name] = OpenStruct.new({ klass: klass, options: options })
    end

    def self.register_serializer(name, klass = nil, options = {})
      @serializers ||= {}

      # allow for 2 arguments (automatically figure out class if so)
      if !klass.is_a?(Class)
        # klass is options. autoamtically figure out klass and set options
        temp = klass || options
        class_name = name.to_s.camelize
        klass = "RubyJsonApiClient::#{class_name}Serializer".constantize
        options = temp
      end

      @serializers[name] = OpenStruct.new({ klass: klass, options: options })
    end

    def self.get_serializer(name)
      @serializers ||= {}
      if @serializers[name]
        @serializers[name].klass.new(@serializers[name].options)
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
      serializer.extract_single(klass, id, response).try(:tap) do |model|
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

    def find_many_relationship(parent, name, options)
      # needs to use adapter_for_class
      serializer = @default_serializer

      # ensure parent is loaded
      reload(parent) if parent.__origin__.nil?

      response = parent.__origin__

      # find the relationship
      list = serializer.extract_many_relationship(parent, name, options, response).map do |model|
        model.__origin__ = response if model.__origin__.nil?
        model
      end

      # wrap in enumerable proxy to allow reloading
      collection = RubyJsonApiClient::Collection.new(list)
      collection.__origin__ = response
      collection
    end

    def find_single_relationship(parent, name, options)
      # needs to use serializer_for_class
      serializer = @default_serializer

      reload(parent) if parent.__origin__.nil?

      response = parent.__origin__

      serializer.extract_single_relationship(parent, name, options, response).tap do |model|
        model.__origin__ = response if model && model.__origin__.nil?
      end
    end

    # TODO: make the 2 following functions a bit nicer
    def load_collection(klass, url)
      adapter = adapter_for_class(klass)
      serializer = serializer_for_class(klass)
      response = adapter.get(url)
      serializer.extract_many(klass, response).map do |model|
        model.__origin__ = response
        model
      end
    end

    # TODO: make nicer
    def load_single(klass, id, url)
      adapter = adapter_for_class(klass)
      serializer = serializer_for_class(klass)
      response = adapter.get(url)
      serializer.extract_single(klass, id, response).tap do |model|
        model.__origin__ = response
      end
    end

    def load(klass, data)

    end

    def reload(model)
      new_model = find(model.class, model.id)
      merge(model, new_model)
    end

    def save(model)
      klass = model.class
      adapter = adapter_for_class(klass)
      serializer = serializer_for_class(klass)
      data = serializer.to_data(model)

      if model.persisted?
        response = adapter.update(model, data)
      else
        response = adapter.create(model, data)
      end

      if response && response != ""
        # convert response into model if there is one.
        # should probably rely on adapter status (error, not changed, changed). etc
        #
        # TODO: can we just use serializer to load data into model?
        new_model = serializer.extract_single(klass, model.id, response).tap do |m|
          m.__origin__ = response
        end

        merge(model, new_model)
      end

      # TODO: Handle failures
      true
    end

    def delete(model)
      if model.persisted?
        klass = model.class
        adapter = adapter_for_class(klass)
        adapter.delete(model)
      end

      # TODO: Handle failures
      true
    end

    def merge(into, from)
      into.__origin__ = from.__origin__
      into.meta = from.meta

      from.class.fields.reduce(into) do |model, attr|
        call = "#{attr}="
        model.send(call, from.send(attr)) if model.respond_to?(call)
        model
      end
    end

  end
end

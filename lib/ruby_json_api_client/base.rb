require 'active_model'
require 'active_support'

module RubyJsonApiClient
  class Base
    include ActiveModel::Model
    include ActiveModel::AttributeMethods
    include ActiveModel::Serialization

    if defined?(ActiveModel::SerializerSupport)
      include ActiveModel::SerializerSupport
    end

    def self.field(name, type = :string)
      fields << name
      attr_accessor name
    end

    def self.fields
      @_fields ||= Set.new [_identifier]
    end

    def self.has_field?(name)
      fields.include?(name)
    end

    def self.identifier(name)
      @_identifier = name
      field(name, :number)
    end

    def self._identifier
      @_identifier || superclass._identifier
    end

    identifier :id
    attr_accessor :meta
    attr_accessor :__origin__

    def self.has_many(name, options = {})
      @_has_many_relationships ||= []
      @_has_many_relationships << name

      define_method(name) do
        @_loaded_has_manys ||= {}

        if @_loaded_has_manys[name].nil?
          result = RubyJsonApiClient::Store
            .instance
            .find_many_relationship(self, name, options)

          @_loaded_has_manys[name] = result
        end

        @_loaded_has_manys[name]
      end
    end

    def self.has_many_relationships
      @_has_many_relationships
    end

    def self.has_one(name, options = {})
      define_method(name) do
        @_loaded_has_ones ||= {}

        if @_loaded_has_ones[name].nil?
          result = RubyJsonApiClient::Store
            .instance
            .find_single_relationship(self, name, options)

          @_loaded_has_ones[name] = result
        end

        @_loaded_has_ones[name]
      end

      define_method("#{name}=".to_sym) do |related|
        @_loaded_has_ones ||= {}
        @_loaded_has_ones[name] = related
      end

      define_method("#{name}_id=".to_sym) do |related_id|
        klass_name = options[:class_name] || ActiveSupport::Inflector.classify(name)
        klass = ActiveSupport::Inflector.constantize(klass_name)
        @_loaded_has_ones ||= {}
        @_loaded_has_ones[name] = klass.new(id: related_id)
      end
    end

    def loaded_has_ones
      @_loaded_has_ones || {}
    end

    def self.find(id)
      RubyJsonApiClient::Store.instance.find(self, id)
    end

    def self.all
      where({})
    end

    def self.where(params)
      RubyJsonApiClient::Store.instance.query(self, params)
    end

    def persisted?
      !!send(self.class._identifier)
    end

    def reload
      RubyJsonApiClient::Store.instance.reload(self)
    end

    def save
      RubyJsonApiClient::Store.instance.save(self)
    end

    def update_attributes(data)
      data.each do |(key, value)|
        self.send("#{key}=", value)
      end
      save
    end

    def ==(other)
      klass_match = (self.class == other.class)
      ids_match = (send(self.class._identifier) == other.send(other.class._identifier))

      klass_match && ids_match
    end
    alias_method :eql?, :==
    alias_method :equal?, :==
  end
end

module RubyJsonApiClient
  class Base
    include ActiveModel::Model
    include ActiveModel::AttributeMethods

    def self.field(name, type = :string)
      @_fields ||= []
      @_fields << name
      attr_accessor name
    end

    def self.fields
      @_fields || []
    end

    def self.has_field?(name)
      (@_fields | [_identifier]).include?(name)
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

    def self.belongs_to(name)

    end

    def self.has_many(name)
      define_method(name) do
        # make cachable
        RubyJsonApiClient::Store.instance.find_many_relationship(self, name)
      end
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

    def links
      store.find(self.class._identifier).__data__
    end

  end
end

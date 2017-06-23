class Person < RubyJsonApiClient::Base
  field :firstname
  field :lastname

  has_many :items
  has_many :other_items, class_name: 'Item'

  has_one :item
  has_one :favorite_item, class_name: 'Item'

  def full_name
    "#{firstname} #{lastname}"
  end
end

class Item < RubyJsonApiClient::Base
  field :name
end

class CellPhone < RubyJsonApiClient::Base
  field :number
end

class Thing < RubyJsonApiClient::Base
  identifier :uuid
end

class Nothing < RubyJsonApiClient::Base
end

module LocalNamespace
  class TestClass < RubyJsonApiClient::Base
    remote_class "SomeOtherClass"
  end
end

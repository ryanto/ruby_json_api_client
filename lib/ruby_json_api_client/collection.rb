module RubyJsonApiClient
  class Collection < BasicObject
    attr_accessor :__origin__

    def initialize(list)
      @list = list
    end

    def method_missing(name, *args, &blk)
      @list.send(name, *args, &blk)
    end
  end
end

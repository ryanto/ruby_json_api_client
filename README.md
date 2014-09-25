# RubyJsonApiClient

A library for creating models from API endpoints.

Imagine an API endpoint that looks like this

    # http://www.example.com/blogs/1
    {
      blog: {
        id: 1,
        name: "A blog",
        links: {
          posts: "/posts?blog_id=1"
        }
      }
    }

RubyJsonApiClient allows you to write

    class Blog < RubyJsonApiClient::Base
      field :name
      has_many :posts
    end

    Blog.find(1).name
    # => "A blog"

    Blog.find(1).posts.map(&:title)
    # => ["Rails is Omakase"]


It has multiple API adapters so working with any serialization format is
easy.

#### Currently support formats
* Active Model Serializers

## Installation

Add this line to your application's Gemfile:

    gem 'ruby_json_api_client'

And then execute:

    $ bundle

## Usage

#### Setting up the adapter/serializer

The first thing that needs to be done is creating an adapter and
serializer. It is recommended you use one of the adapters that ships
with this gem.

For this example, we will setup an adapter that reads from
ActiveModelSerializers based APIs.

    # config/initializers/ruby_json_api_client.rb

    # Setup the AMS adapter to pull from https://www.example.com
    RubyJsonApiClient::Store.register_adapter(:ams, {
      hostname: 'www.example.com',
      secure: true
    });

    # Use AMS based serializer
    RubyJsonApiClient::Store.register_serializer(:ams)

    # Default all models to AMS
    RubyJsonApiClient::Store.default(:ams)


#### Models

Now you can setup your classes based on your API endpoints.

    class Book < RubyJsonApiClient::Base
      field :title
      has_one :author
    end

    Book.all
    # => Loads collection from https://www.example.com/books

    Book.query(type: 'fiction')
    # => Loads collection from https://www.example.com/books?type=fiction

    Book.find(1)
    # => Loads model from https://www.example.com/books/1

#### Relationships

Most relationships rules are defined based on the semantics of the
adapter you choose. For example, when using Active Model Serializers
relationships are mostly likely going to be sideloaded or accessed by
links.

    class Book < RubyJsonApiClient::Base
      field :title
      has_one :author
    end

    class Author < RubyJsonApiClient::Base
      field :name
      has_many :books
    end

With an AMS API that sideloads relationships, such as:

    # http://www.example.com/books
    {
      books: [{
        id: 1,
        title: "Example book",
        author_id: 123
      }],
      authors: [{
        id: 123,
        name: "Test author"
        book_ids: [1]
      }]
    }

We could do the following.

    Book.find(1).author.name
    # => "Test author"

    Author.find(123).books
    # => [Book(<id: 1>)]

There are many more ways to load relationship data. You should consult
the adapter guide based on which adapter you are using.

## TODO

* Per model serializers and adapters (Store#adapter_for_class)
* Store#find_many_relationship should return reloadable proxy
* Store#find_single_relationship should return reloadable proxy
* Write AMS adapter docs
* Write docs for custom adapter
* Auto figure out default serializer from registered adapter(s)
* has one should accept field_id = 123. Post.find(1).author_id = 5
* Adapter/serializer should be able to add methods to models
  (author_id=)
* Faraday follow redirectos
* Faraday cache
* REST handle 4xx errors

#### AMS

* serializer: json to model rename data to model

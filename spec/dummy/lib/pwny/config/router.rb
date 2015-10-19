module Pwny
  module Config
    class Router
      include Quiver::Router

      routes do
        get '/hello_world', to: 'hello_world#index'
        post '/post', to: 'hello_world#post'
      end
    end
  end
end

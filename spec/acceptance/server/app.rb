# frozen_string_literal: true

require "sinatra"

get "/health" do
  status 200
  body "ok"
end

get "/" do
  "Hello, world!"
end

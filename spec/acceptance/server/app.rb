# frozen_string_literal: true

require "sinatra"
require "json"

# Helper to parse JSON payloads
helpers do
  def parse_json_payload
    request_body = request.body.read
    return [400, "No JSON payload received"] if request_body.empty?

    begin
      json_payload = JSON.parse(request_body)
      [nil, json_payload]
    rescue JSON::ParserError
      [400, "Invalid JSON payload"]
    end
  end

  def format_query_params
    params.map { |key, value| "#{key}: #{value}" }.join(", ")
  end
end

# Health check endpoint
get "/health" do
  status 200
  body "ok"
end

# Root endpoint
get "/" do
  "Hello, world!"
end

# Handle HEAD requests
head "/resource" do
  status 200
end

# Handle GET requests with query params
get "/resource" do
  query_params = format_query_params
  status 200
  body query_params.empty? ? "GET request received" : "Received query params: #{query_params}"
end

# Handle POST, PUT, and PATCH requests with JSON payload
[:post, :put, :patch].each do |method|
  send(method, "/resource") do # rubocop:disable GitHub/AvoidObjectSendWithDynamicMethod
    error_status, payload = parse_json_payload
    if error_status
      status error_status
      body payload
    else
      status method == :post ? 201 : 200
      body "#{method.to_s.upcase} request received with payload: #{payload.to_json}"
    end
  end
end

# Handle DELETE requests with query params
delete "/resource" do
  query_params = format_query_params
  status 200
  body query_params.empty? ? "DELETE request received" : "Deleted resource with params: #{query_params}"
end

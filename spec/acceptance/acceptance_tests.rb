# frozen_string_literal: true

require "rspec"
require_relative "../../lib/net/http/ext"

MAX_WAIT_TIME = 30 # how long to wait for the server to start

describe "Net::HTTP::Ext" do
  let(:http) { Net::HTTP::Ext.new("http://127.0.0.1:8080") }

  before(:all) do
    start_time = Time.now
    loop do
      response = Net::HTTP::Ext.new("http://127.0.0.1:8080").get("/health")
      break if response.is_a?(Net::HTTPSuccess)

      if Time.now - start_time > MAX_WAIT_TIME
        raise "did not return a 200 within #{MAX_WAIT_TIME} seconds"
      end

      sleep 1
    end
  end

  describe "#get" do
    it "successfully makes a GET request" do
      response = http.get("/health")
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("200")
      expect(response.body).to eq("ok")
    end

    it "successfully makes a GET request with query params" do
      response = http.get("/resource?key=value")
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("200")
      expect(response.body).to include("key: value")
    end
  end

  describe "#head" do
    it "successfully makes a HEAD request" do
      response = http.head("/resource")
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("200")
      expect(response.body).to be_nil
    end
  end

  describe "#post" do
    it "successfully makes a POST request with JSON payload" do
      payload = { name: "test" }

      response = http.post(
        "/resource",
        payload:,
        headers: { "Content-Type" => "application/json" }
      )
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("201")
      expect(response.body).to include("POST request received with payload: #{payload.to_json}")
      expect(response.body).to include('"name":"test"')
    end

    it "successfully makes a POST request with JSON payload that has already been cast with to_json and no headers are set" do
      payload = { name: "test" }

      response = http.post(
        "/resource",
        payload: payload.to_json
      )
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("201")
      expect(response.body).to include("POST request received with payload: #{payload.to_json}")
      expect(response.body).to include('"name":"test"')
    end

    it "successfully makes a POST request with JSON payload that has already been cast with to_json and headers are set" do
      payload = { name: "test" }

      response = http.post(
        "/resource",
        payload: payload.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("201")
      expect(response.body).to include("POST request received with payload: #{payload.to_json}")
      expect(response.body).to include('"name":"test"')
    end

    it "successfully makes a POST request with a JSON payload that is not a symbolized hash" do
      payload = { "name" => "test" }
      response = http.post(
        "/resource",
        payload: payload.to_json
      )
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("201")
      expect(response.body).to include("POST request received with payload: #{payload.to_json}")
      expect(response.body).to include('"name":"test"')
    end
  end

  describe "#put" do
    it "successfully makes a PUT request with JSON payload" do
      payload = { name: "updated" }

      response = http.put(
        "/resource",
        payload:,
        headers: { "Content-Type" => "application/json" }
      )
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("200")
      expect(response.body).to include("PUT request received with payload: #{payload.to_json}")
      expect(response.body).to include('"name":"updated"')
    end
  end

  describe "#patch" do
    it "successfully makes a PATCH request with JSON payload" do
      payload = { name: "patched" }

      response = http.patch(
        "/resource",
        payload:,
        headers: { "Content-Type" => "application/json" }
      )
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("200")
      expect(response.body).to include("PATCH request received with payload: #{payload.to_json}")
      expect(response.body).to include('"name":"patched"')
    end
  end

  describe "#delete" do
    it "successfully makes a DELETE request with query params" do
      response = http.delete("/resource?key=value")
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("200")
      expect(response.body).to include("Deleted resource with params")
      expect(response.body).to include("key: value")
    end

    it "successfully makes a DELETE request without query params" do
      response = http.delete("/resource")
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("200")
      expect(response.body).to eq("DELETE request received")
    end
  end
end

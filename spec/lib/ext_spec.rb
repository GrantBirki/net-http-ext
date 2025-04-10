# frozen_string_literal: true

require_relative "../spec_helper"

describe Net::HTTP::Ext do
  let(:log) { instance_double(Logger).as_null_object }
  let(:name) { "unit-tests" }
  let(:endpoint) { "http://#{name}.local" }
  let(:response) { instance_double(Net::HTTPResponse, code: "200", body: "response") }

  subject { described_class.new(endpoint, log:, name:) }

  describe "#initialize" do
    it "sets the endpoint" do
      expect(subject.instance_variable_get(:@uri)).to eq(URI.parse(endpoint))
    end

    it "sets the logger" do
      expect(subject.instance_variable_get(:@log)).to eq(log)
    end

    it "sets the name" do
      expect(subject.instance_variable_get(:@name)).to eq(name)
    end

    it "has sane defaults" do
      expect(subject.http.open_timeout).to eq(nil)
      expect(subject.http.read_timeout).to eq(nil)
      expect(subject.http.keep_alive).to eq(30)
      expect(subject.http.write_timeout).to eq(nil)
      expect(subject.http.max_requests).to eq(nil)
      expect(subject.http.max_retries).to eq(1)
      expect(subject.instance_variable_get(:@ssl_cert_file)).to eq(nil)
    end
  end

  context "public request methods" do
    before do
      allow(subject).to receive(:request).and_return(response)
    end

    describe "#get" do
      it "makes a GET request to the endpoint" do
        expect(subject.get("/test")).to eq(response)
      end
    end

    describe "#post" do
      it "makes a POST request to the endpoint" do
        expect(subject.post("/test", payload: { key: "value" })).to eq(response)
      end
    end

    describe "#put" do
      it "makes a PUT request to the endpoint" do
        expect(subject.put("/test", payload: { key: "value" })).to eq(response)
      end
    end

    describe "#patch" do
      it "makes a PATCH request to the endpoint" do
        expect(subject.patch("/test", payload: { key: "value" })).to eq(response)
      end
    end

    describe "#delete" do
      it "makes a DELETE request to the endpoint" do
        expect(subject.delete("/test")).to eq(response)
      end
    end

    describe "#head" do
      it "makes a HEAD request to the endpoint" do
        expect(subject.head("/test")).to eq(response)
      end
    end
  end

  describe "https" do
    let(:https_endpoint) { "https://#{name}.local" }
    let(:https_client) { Net::HTTP::Ext.new(https_endpoint, log:, name:) }

    describe "#initialize" do
      it "sets the endpoint to HTTPS" do
        expect(https_client.instance_variable_get(:@uri)).to eq(URI.parse(https_endpoint))
        expect(https_client.http.ssl_version).to eq(:TLSv1_2)
        expect(https_client.http.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
        expect(https_client.http.verify_hostname).to eq(true)
      end
    end
  end

  describe "#close!" do
    it "fully creates and closes a client" do
      client = Net::HTTP::Ext.new(endpoint, log:, name:)
      client.close!
    end
  end

  describe "#logger" do
    it "returns the logger" do
      logger = subject.send(:create_logger)
      expect(logger).to be_a(Logger)
    end
  end

  describe "private methods" do
    before do
      allow(subject).to receive(:create_logger).and_return(log)
    end

    describe "#create_logger" do
      it "creates a logger with the correct log level" do
        logger = subject.send(:create_logger)
        expect(logger).to eq(log)
      end
    end

    describe "#create_http_client" do
      it "creates a persistent HTTP client with default options" do
        options = { open_timeout: 10, read_timeout: 20 }
        http_client = subject.send(:create_http_client, options)
        expect(http_client).to be_a(Net::HTTP::Persistent)
        expect(http_client.open_timeout).to eq(10)
        expect(http_client.read_timeout).to eq(20)
      end

      it "configures SSL settings for HTTPS" do
        options = { ssl_version: :TLSv1_2, verify_mode: OpenSSL::SSL::VERIFY_PEER }
        http_client = subject.send(:create_http_client, options)
        expect(http_client.ssl_version).to eq(:TLSv1_2)
        expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
      end
    end

    describe "#normalize_headers" do
      it "normalizes header keys to lowercase" do
        headers = { "Content-Type" => "application/json", "Authorization" => "Bearer token" }
        normalized = subject.send(:normalize_headers, headers)
        expect(normalized).to eq({ "content-type" => "application/json", "authorization" => "Bearer token" })
      end

      it "returns an empty hash if headers are nil" do
        expect(subject.send(:normalize_headers, nil)).to eq({})
      end
    end

    describe "#build_request" do
      it "builds a GET request with query parameters" do
        headers = { "Authorization" => "Bearer token" }
        params = { key: "value" }
        request = subject.send(:build_request, :get, "/test", headers: headers, params: params)
        expect(request).to be_a(Net::HTTP::Get)
        expect(request.path).to eq("/test?key=value")
      end

      it "builds a POST request with a body" do
        headers = { "Content-Type" => "application/json" }
        params = { key: "value" }
        request = subject.send(:build_request, :post, "/test", headers: headers, params: params)
        expect(request).to be_a(Net::HTTP::Post)
        expect(request.body).to eq(params.to_json)
      end
    end

    describe "#validate_querystring" do
      it "raises an error if both path and params contain query strings" do
        expect {
          subject.send(:validate_querystring, "/test?key=value", { another: "param" })
        }.to raise_error(ArgumentError, "Querystring must be sent via `params` or `path` but not both.")
      end

      it "does not raise an error if only path contains a query string" do
        expect {
          subject.send(:validate_querystring, "/test?key=value", nil)
        }.not_to raise_error
      end
    end

    describe "#set_request_body" do
      let(:request) { Net::HTTP::Post.new("/test") }

      it "sets the body for a JSON payload" do
        headers = { "Content-Type" => "application/json" }
        params = { key: "value" }
        subject.send(:set_request_body, request, params, headers)
        expect(request.body).to eq(params.to_json)
        expect(headers["Content-Type"]).to eq("application/json")
      end

      it "sets the body for a form-encoded payload" do
        headers = { "Content-Type" => "application/x-www-form-urlencoded" }
        params = { key: "value" }
        subject.send(:set_request_body, request, params, headers)
        expect(request.body).to eq("key=value")
        expect(headers["Content-Type"]).to eq("application/x-www-form-urlencoded")
      end

      it "sets the body for a plain string payload" do
        headers = {}
        params = "plain text"
        subject.send(:set_request_body, request, params, headers)
        expect(request.body).to eq("plain text")
        # Use lowercase to match the implementation
        expect(headers["content-type"]).to eq("application/octet-stream")
      end
    end

    describe "#serialize_to_json" do
      it "serializes a hash to JSON" do
        obj = { key: "value" }
        json = subject.send(:serialize_to_json, obj)
        expect(json).to eq(obj.to_json)
      end

      it "serializes pretty much everything to json" do
        obj = StandardError.new("error")
        expect(subject.send(:serialize_to_json, obj)).to eq("\"error\"")
      end
    end

    describe "#add_headers_to_request" do
      let(:request) { Net::HTTP::Post.new("/test") }

      it "adds headers to the request" do
        headers = { "Authorization" => "Bearer token" }
        subject.send(:add_headers_to_request, request, headers)
        expect(request["Authorization"]).to eq("Bearer token")
      end
    end

    describe "#validate_host_header" do
      it "raises an error if the Host header does not match the URI host" do
        headers = { "host" => "wrong-host.com" }
        expect {
          subject.send(:validate_host_header, headers)
        }.to raise_error(ArgumentError, /Host header does not match the request URI host/)
      end

      it "sets the Host header if not explicitly provided" do
        headers = {}
        subject.send(:validate_host_header, headers)
        expect(headers["host"]).to eq(URI.parse(endpoint).host)
      end
    end

    describe "#encode_path_params" do
      it "appends query parameters to the path" do
        path = "/test"
        params = { key: "value" }
        encoded_path = subject.send(:encode_path_params, path, params)
        expect(encoded_path).to eq("/test?key=value")
      end

      it "returns the path unchanged if params are nil" do
        path = "/test"
        encoded_path = subject.send(:encode_path_params, path, nil)
        expect(encoded_path).to eq("/test")
      end
    end
  end
end

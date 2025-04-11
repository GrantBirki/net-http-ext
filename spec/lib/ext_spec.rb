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
      expect(subject.http.idle_timeout).to eq(5)
      expect(subject.http.max_requests).to eq(nil)
      expect(subject.http.max_retries).to eq(1)
      expect(subject.instance_variable_get(:@ssl_cert_file)).to eq(nil)
    end

    it "logs a warning with an unsupported option" do
      expect(log).to receive(:debug).with("Ignoring unsupported option: unsupported_option")
      described_class.new(endpoint, log:, name:, unsupported_option: true)
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

    describe "#get_json" do
      it "makes a GET request and parses the JSON response" do
        allow(response).to receive(:body).and_return("{\"key\":\"value\"}")
        expect(subject.get_json("/test")).to eq({ "key" => "value" })
      end

      it "raises an error if the response is not valid JSON" do
        allow(response).to receive(:body).and_return("invalid json")
        expect {
          subject.get_json("/test")
        }.to raise_error(JSON::ParserError, /unexpected character/)
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

    describe "#set_default_headers" do
      it "sets default headers for the request" do
        headers = { "User-Agent" => "MyApp" }
        subject.set_default_headers(headers)
        expect(subject.default_headers).to eq({ "user-agent" => "MyApp" })
      end
    end

    describe "#build_request" do
      it "builds a GET request with query parameters" do
        headers = { "Authorization" => "Bearer token" }
        params = { key: "value" }
        request = subject.send(:build_request, :get, "/test", headers: headers, params: params)
        expect(request).to be_a(Net::HTTP::Get)
        expect(request.path).to eq("/test?key=value")
        expect(request["Authorization"]).to eq("Bearer token")
      end

      it "builds a GET request with nil headers" do
        headers = nil
        params = { key: "value" }
        request = subject.send(:build_request, :get, "/test", headers: headers, params: params)
        expect(request).to be_a(Net::HTTP::Get)
        expect(request.path).to eq("/test?key=value")
        expect(request["content-type"]).to eq(nil)
      end

      it "builds a GET request with the content-type header set to nil" do
        headers = { "content-type" => nil }
        params = { key: "value" }
        request = subject.send(:build_request, :get, "/test", headers: headers, params: params)
        expect(request).to be_a(Net::HTTP::Get)
        expect(request.path).to eq("/test?key=value")
        expect(request["content-type"]).to eq(nil)
      end

      it "builds a GET request with unset headers" do
        headers = {}
        params = { key: "value" }
        request = subject.send(:build_request, :get, "/test", headers: headers, params: params)
        expect(request).to be_a(Net::HTTP::Get)
        expect(request.path).to eq("/test?key=value")
        expect(request["content-type"]).to eq(nil)
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

      it "sets the body when no Content-Type is provided" do
        headers = {}
        params = { key: "value" }
        subject.send(:set_request_body, request, params, headers)
        expect(request.body).to eq(params.to_json)
        expect(headers["content-type"]).to eq("application/json")
      end

      it "raises an ArgumentError when params are not a hash for form URL-encoded requests" do
        headers = { "Content-Type" => "application/x-www-form-urlencoded" }
        params = Object.new
        expect {
          subject.send(:set_request_body, request, params, headers)
        }.to raise_error(ArgumentError, /Failed to set request body/)
      end

      it "fails when headers are of a bad type" do
        headers = Object.new
        params = { key: "value" }
        expect {
          subject.send(:set_request_body, request, params, headers)
        }.to raise_error(ArgumentError, /Failed to set request body/)
      end

      it "works when headers are nil" do
        headers = nil
        params = { key: "value" }
        subject.send(:set_request_body, request, params, headers)
        expect(request.body).to eq(params.to_json)
        expect(headers).to be_nil
      end

      it "works with a downcase Content-Type" do
        headers = { "content-type" => "application/json" }
        params = { key: "value" }
        subject.send(:set_request_body, request, params, headers)
        expect(request.body).to eq(params.to_json)
        expect(headers["content-type"]).to eq("application/json")
      end

      it "works with a downcase custom Content-Type" do
        headers = { "content-type" => "some/custom/content/type" }
        params = { key: "value" }
        subject.send(:set_request_body, request, params, headers)
        expect(request.body).to eq(params.to_json)
        expect(headers["content-type"]).to eq("some/custom/content/type")
      end

      it "defaults to the provided content type" do
        headers = { "Content-Type" => "some/custom/content/type" }
        params = { key: "value" }
        subject.send(:set_request_body, request, params, headers)
        expect(request.body).to eq(params.to_json)
        expect(headers["Content-Type"]).to eq("some/custom/content/type")
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

    describe "#format_duration_ms" do
      it "formats the duration in milliseconds" do
        duration = 5.43219 # seconds
        formatted_duration = subject.send(:format_duration_ms, duration)
        expect(formatted_duration).to eq("5432.19 ms")
      end
    end

    describe "#request" do
      let(:http_request) { instance_double(Net::HTTP::Get) }
      let(:success_response) { instance_double(Net::HTTPResponse, code: "200", body: "success") }

      before do
        allow(subject).to receive(:build_request).and_return(http_request)
        allow(subject).to receive(:format_duration_ms).and_return("10.00 ms")
      end

      context "when the request succeeds" do
        it "returns the response" do
          allow(subject.http).to receive(:request).and_return(success_response)

          response = subject.send(:request, :get, "/users")

          expect(response).to eq(success_response)
          expect(log).to have_received(:debug).with(/Request completed/)
          expect(subject.http).to have_received(:request).once
        end
      end

      context "with request_timeout unset" do
        let(:subject) { described_class.new(endpoint, log: log, request_timeout: nil) }

        it "returns the response if successful" do
          allow(subject.http).to receive(:request).and_return(success_response)
          response = subject.send(:request, :get, "/users")
          expect(response).to eq(success_response)
          expect(log).to have_received(:debug).with(/Request completed/)
          expect(subject.http).to have_received(:request).once
        end
      end

      context "with a request timeout configured" do
        let(:subject) { described_class.new(endpoint, log: log, request_timeout: 5) }

        it "applies the timeout and returns the response if successful" do
          expect(Timeout).to receive(:timeout).with(5).and_yield
          allow(subject.http).to receive(:request).and_return(success_response)

          response = subject.send(:request, :get, "/users")

          expect(response).to eq(success_response)
        end

        it "raises a Timeout::Error when the request times out" do
          expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)

          expect {
            subject.send(:request, :get, "/users")
          }.to raise_error(Timeout::Error)

          expect(log).to have_received(:error).with(/Request timed out/)
        end
      end

      context "when errors occur" do
        context "with retries" do
          let(:subject) { described_class.new(endpoint, log: log, max_retries: 2) }
          let(:new_http_client) { instance_double(Net::HTTP::Persistent) }

          it "retries the request when Net::HTTP::Persistent::Error occurs and succeeds" do
            # Setup the HTTP client that will replace the original after failure
            allow(subject).to receive(:create_http_client).and_return(new_http_client)

            # First request fails, second succeeds
            allow(subject.http).to receive(:request).and_raise(Net::HTTP::Persistent::Error)
            allow(new_http_client).to receive(:request).and_return(success_response)

            response = subject.send(:request, :get, "/users")

            expect(response).to eq(success_response)
            # The first client receives one request (which fails)
            expect(subject.http).to have_received(:request).once
            # The new client receives one request (which succeeds)
            expect(new_http_client).to have_received(:request).once
            expect(log).to have_received(:debug).with(/Connection failed.*retry 1\/2/)
          end

          it "retries the request when Errno::ECONNRESET occurs and succeeds" do
            # Setup the HTTP client that will replace the original after failure
            allow(subject).to receive(:create_http_client).and_return(new_http_client)

            # First request fails, second succeeds
            allow(subject.http).to receive(:request).and_raise(Errno::ECONNRESET)
            allow(new_http_client).to receive(:request).and_return(success_response)

            response = subject.send(:request, :get, "/users")

            expect(response).to eq(success_response)
            # Verify both clients received requests
            expect(subject.http).to have_received(:request).once
            expect(new_http_client).to have_received(:request).once
          end
        end

        context "with no retries" do
          let(:subject) { described_class.new(endpoint, log: log, max_retries: 0) }

          it "doesn't retry when max_retries is 0" do
            allow(subject.http).to receive(:request).and_raise(Net::HTTP::Persistent::Error)

            expect {
              subject.send(:request, :get, "/users")
            }.to raise_error(Net::HTTP::Persistent::Error)

            expect(subject.http).to have_received(:request).once
            expect(log).to have_received(:error).with(/Connection failed after 0 retries/)
          end
        end
      end

      context "with logging" do
        it "logs request completion with timing" do
          allow(subject.http).to receive(:request).and_return(success_response)

          subject.send(:request, :get, "/users")

          expect(log).to have_received(:debug).with(
            "Request completed: method=get, path=/users, status=200, duration=10.00 ms"
          )
        end

        it "logs timeouts with timing" do
          expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)

          expect {
            subject.send(:request, :get, "/users")
          }.to raise_error(Timeout::Error)

          expect(log).to have_received(:error).with(
            "Request timed out after 10.00 ms: method=get, path=/users"
          )
        end
      end
    end
  end
end

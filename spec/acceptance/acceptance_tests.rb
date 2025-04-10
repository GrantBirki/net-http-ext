# frozen_string_literal: true

require "rspec"
require_relative "../../lib/net/http/ext"

describe "Net::HTTP::Ext" do
  let(:http) { Net::HTTP::Ext.new("http://127.0.0.1:8080") }

  describe "#get" do
    it "successfully makes a GET request" do
      response = http.get("/health")
      expect(response).to be_a(Net::HTTPResponse)
      expect(response.code).to eq("200")
      expect(response.body).to eq("ok")
    end
  end
end

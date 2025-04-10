# frozen_string_literal: true

require_relative "../spec_helper"

describe Net::HTTP::Ext do
  let(:log) { instance_double(Logger).as_null_object }
  let(:name) { "unit-tests" }
  let(:endpoint) { "http://#{name}.local" }

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
  end
end

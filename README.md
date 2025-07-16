# net-http-ext

[![test](https://github.com/GrantBirki/net-http-ext/actions/workflows/test.yml/badge.svg)](https://github.com/GrantBirki/net-http-ext/actions/workflows/test.yml)
[![lint](https://github.com/GrantBirki/net-http-ext/actions/workflows/lint.yml/badge.svg)](https://github.com/GrantBirki/net-http-ext/actions/workflows/lint.yml)
[![acceptance](https://github.com/GrantBirki/net-http-ext/actions/workflows/acceptance.yml/badge.svg)](https://github.com/GrantBirki/net-http-ext/actions/workflows/acceptance.yml)
[![build](https://github.com/GrantBirki/net-http-ext/actions/workflows/build.yml/badge.svg)](https://github.com/GrantBirki/net-http-ext/actions/workflows/build.yml)
[![release](https://github.com/GrantBirki/net-http-ext/actions/workflows/release.yml/badge.svg)](https://github.com/GrantBirki/net-http-ext/actions/workflows/release.yml)

Safe defaults, persistent connections, thread safety, and basic logging for Ruby's Net::HTTP library.

A simple wrapper around [`net/http/persistent`](https://github.com/drbrain/net-http-persistent) in pure Ruby.

## About 💡

A very simple wrapper around the `net/http/persistent` library (which is a wrapper around `net/http`) that provides a few extra features and safe defaults. It is designed to be a *lite*-batteries-included version of `net/http/persistent` that is easy to use and configure.

Should you need anything more complex, check out [`faraday`](https://github.com/lostisland/faraday) + [`faraday-net_http_persistent`](https://github.com/lostisland/faraday-net_http_persistent).

### Benefits ⭐

1. Reuse connections for multiple requests
2. Thread safe
3. Secure defaults
4. Basic logging
5. Automatically rebuild the connection if it is closed by the server
6. Automatically retry requests on connection failures if `max_retries` is set to a value >1
7. Easy to use and configure

## Installation 💎

You can download this Gem from [GitHub Packages](https://github.com/GrantBirki/net-http-ext/pkgs/rubygems/net-http-ext) or [RubyGems](https://rubygems.org/gems/net-http-ext)

Via a Gemfile:

```ruby
source "https://rubygems.org"

gem "net-http-ext", "~> X.X.X" # Replace X.X.X with the latest version
```

Via the CLI:

```bash
gem install net-http-ext
```

## Usage 💻

## Basic Usage

Here is an example using the library in its most basic form:

```ruby
require "net/http/ext"

# initialize the client
client = Net::HTTP::Ext.new("httpbin.org")

# make a request
response = client.get("/")

puts response.code
puts response.body
```

### Extended Usage

Here is a more detailed/full usage example:

```ruby
require "net/http/ext"

# Initialize the client
client = Net::HTTP::Ext.new("httpbin.org")

response = client.get("/")
puts response.code

# GET request with headers and query parameters
response = client.get("/get?param1=value1&param2=value2",
  headers: { "Authorization" => "Bearer token123" }
)
puts response.body

# GET request using query parameters as a qwarg
response = client.get("/get",
  params: { param1: "value1kwarg", param2: "value2kwarg" },
)
puts response.body

# POST request with JSON payload
response = client.post("/post",
  payload: { name: "John Doe", email: "john@example.com" }
)
puts response.body

# POST request with JSON payload and custom content type
response = client.post("/post",
  headers: { "Content-Type" => "application/json+custom" },
  payload: { name: "John Doe", email: "john@example.com" }
)
puts response.body

# Custom timeouts
client = Net::HTTP::Ext.new("https://httpbin.org",
  open_timeout: 5,     # connection establishment timeout (seconds)
  read_timeout: 10,    # response read timeout (seconds)
  idle_timeout: 30,    # how long to keep idle connections open (seconds)
  request_timeout: 15  # overall request timeout (seconds)
)
response = client.get("/delay/2") # Simulate a delay of 2 seconds
puts response.code

# Default headers on all requests
client = Net::HTTP::Ext.new("https://httpbin.org",
  default_headers: {
    "User-Agent" => "MyApp/1.0"
  }
)
response = client.get("/headers")
puts response.body

# Make a get request and automatically parse it as JSON
response = client.get_json("/get?param1=value1&param2=value2")
puts response["args"]["param1"] # => "value1"
```

> See the full source code at [`lib/net/http/ext.rb`](lib/net/http/ext.rb) for more details on the available options and methods.

## Contributing 🤝

1. Fork the repository
2. Bootstrap the project with `script/bootstrap`
3. Create a new branch (`git checkout -b feature/your-feature`)
4. Write your code
5. Run the tests (`script/test`)
6. Run the acceptance tests (`script/acceptance`)
7. Run the linter (`script/lint -A`)
8. Commit your changes (`git commit -m "Add some feature"`)
9. Push to the branch (`git push origin feature/your-feature`)
10. Create a new Pull Request
11. Wait for an approval and passing ci tests
12. 🎉

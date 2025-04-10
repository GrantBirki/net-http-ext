FROM ruby:3.4.2-slim@sha256:342bfeb04d3660045ceba063197d22baafec6b163f019714ddf8fc83c59aabee

RUN apt-get -y update && apt-get -y upgrade

RUN apt-get install -y make gcc curl build-essential g++ libyaml-dev libgmp-dev libxml2-dev libxslt1-dev

WORKDIR /app

# create nonroot user
RUN useradd -m nonroot

COPY --chown=nonroot:nonroot lib/net/http/version.rb ./lib/net/http/version.rb
COPY --chown=nonroot:nonroot .ruby-version Gemfile Gemfile.lock net-http-ext.gemspec ./
COPY --chown=nonroot:nonroot vendor/cache ./vendor/cache
COPY --chown=nonroot:nonroot script ./script

RUN script/bootstrap

COPY --chown=nonroot:nonroot . .

# switch to the nonroot user
USER nonroot

FROM ruby:3.4
MAINTAINER Colin Mitchell <colin@muffinlabs.com>

ARG BUNDLER_VERSION=2.5.6

RUN apt-get update \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN mkdir -p /app
WORKDIR /app

RUN gem install -N bundler -v ${BUNDLER_VERSION}

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN DEST=public/data/ bundle exec ./scrape-wikipedia.rb


CMD ["bundle", "exec", "puma", "config.ru", "-C", "puma.rb"]

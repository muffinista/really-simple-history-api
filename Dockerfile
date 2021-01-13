FROM ruby:2.6.6

ARG BUNDLER_VERSION=2.1.4
ENV BUNDLE_PATH=vendor/bundle BUNDLE_FROZEN=1 BUNDLE_CLEAN=1 BUNDLE_RETRY=3 BUNDLE_JOBS=4

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



CMD ["puma", "config.ru", "-C", "puma.rb"]

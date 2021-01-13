FROM ruby:2.6.5

RUN apt-get update

RUN mkdir -p /app
COPY . /app
WORKDIR /app

RUN bundle install

CMD ["puma", "config.ru", "-C", "puma.rb"]
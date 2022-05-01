FROM ruby:3.0.2-slim-buster

USER root

RUN apt-get update -qq && apt-get install -y \
    build-essential libpq-dev libxml2-dev libxslt1-dev imagemagick apt-transport-https curl nano

ENV APP_HOME /home/www/my_app

WORKDIR $APP_HOME

USER root

COPY Gemfile Gemfile.lock .ruby-version ./

RUN bundle check || bundle install --without development test

COPY . .

RUN RAILS_ENV=staging rails assets:precompile

RUN rm -rf spec tmp/cache

RUN rm $(ls -d $APP_HOME/config/credentials/* | grep -v 'staging')

RUN chmod +x docker/staging/entrypoint.sh

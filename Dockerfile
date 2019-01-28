FROM ruby:2.6.0-alpine3.8
RUN mkdir /cache && apk update && apk add rsync
COPY cache.rb /usr/local/cache.rb

VOLUME /cache
CMD ruby /usr/local/cache.rb

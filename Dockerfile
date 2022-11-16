FROM ruby:3.1.2-slim

COPY Gemfile Gemfile.lock main.rb ./

RUN bundle config --global path /gems
RUN bundle install

CMD ["ruby", "main.rb"]
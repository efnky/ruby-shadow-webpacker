FROM ruby:3.3.11-slim AS builder
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

COPY package.json ./
RUN npm install

COPY . .

RUN bundle exec rake assets:precompile

FROM ruby:3.3.11-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/* && \
    groupadd -r rails && useradd -r -g rails -u 1001 rails

COPY --from=builder /app ./
COPY --from=builder /usr/local/bundle /usr/local/bundle

RUN chown -R rails:rails /app

EXPOSE 3000

USER rails

ENV RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
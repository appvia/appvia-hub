##############################################################
# Stage: builder
FROM ruby:2.5.5-alpine3.9 AS builder

ENV RAILS_ENV production
ENV NODE_ENV production

WORKDIR /app

RUN apk add --update --no-cache bash curl make gcc libc-dev postgresql-client postgresql-dev tzdata nodejs-current yarn

# install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 20 --retry 5 --deployment --without development test

# install yarn packages
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --no-cache --production

# copy app
COPY . /app

# precompile assets
RUN BASE_URL=noop \
  SECRET_KEY_BASE=foo \
  SECRET_SALT=bar \
  DATABASE_URL=postgresql://user:pass@127.0.0.1/dbname \
  bin/rails assets:precompile \
  && rm -rf node_modules tmp/cache app/webpack

##############################################################
# Stage: final
FROM ruby:2.5.5-alpine3.9

LABEL maintainer="info@appvia.io"
LABEL source="https://github.com/appvia/appvia-hub"

ENV RAILS_ENV production
ENV NODE_ENV production
ENV APP_PATH /app

RUN apk add --update --no-cache bash curl postgresql-client tzdata && \
    rm -rf /var/cache/apk/*

RUN addgroup -g 1000 -S appuser \
 && adduser -u 1000 -S appuser -G appuser

USER 1000

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder --chown=1000:1000 /app $APP_PATH

WORKDIR $APP_PATH

ENV HOME $APP_PATH
ENV PORT 3001
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true

ENTRYPOINT ["bin/rails"]
CMD ["server"]

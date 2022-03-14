ARG APP_ROOT=/srv/app
ARG RUBY_VERSION=2.7.5
ARG NODE_VERSION=16.14

FROM ruby:${RUBY_VERSION}-alpine AS gem
ARG APP_ROOT

RUN apk add --no-cache build-base postgresql-dev

RUN mkdir -p ${APP_ROOT}
COPY Gemfile Gemfile.lock ${APP_ROOT}/

WORKDIR ${APP_ROOT}
RUN gem install bundler:2.3.7 \
    && bundle config --local deployment 'true' \
    && bundle config --local frozen 'true' \
    && bundle config --local no-cache 'true' \
    && bundle config --local system 'true' \
    && bundle config --local without 'development test' \
    && bundle install -j "$(getconf _NPROCESSORS_ONLN)" \
    && find /${APP_ROOT}/vendor/bundle -type f -name '*.c' -delete \
    && find /${APP_ROOT}/vendor/bundle -type f -name '*.o' -delete \
    && find /usr/local/bundle -type f -name '*.c' -delete \
    && find /usr/local/bundle -type f -name '*.o' -delete \
    && rm -rf /usr/local/bundle/cache/*.gem


FROM node:${NODE_VERSION}-alpine as node
ARG SERVER_ROOT

FROM ruby:${RUBY_VERSION}-alpine
ARG APP_ROOT

RUN apk add --no-cache curl tzdata shared-mime-info postgresql-libs imagemagick

COPY --from=gem /usr/local/bundle/config /usr/local/bundle/config
COPY --from=gem /usr/local/bundle /usr/local/bundle
COPY --from=gem /${APP_ROOT}/vendor/bundle /${APP_ROOT}/vendor/bundle

COPY --from=node /usr/local/bin/node /usr/local/bin/node

RUN mkdir -p ${APP_ROOT}

ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=yes
ENV APP_ROOT=$APP_ROOT

COPY . ${APP_ROOT}

ARG REVISION
ENV REVISION $REVISION
RUN echo $REVISION > ${SERVER_ROOT}/REVISION

# Apply Execute Permission
RUN adduser -h ${APP_ROOT} -D -s /bin/nologin ruby ruby && \
    chown ruby:ruby ${APP_ROOT} && \
    chown -R ruby:ruby ${APP_ROOT}/log && \
    chown -R ruby:ruby ${APP_ROOT}/tmp && \
    chmod -R +r ${APP_ROOT}

USER ruby
WORKDIR ${APP_ROOT}

EXPOSE 3000
HEALTHCHECK CMD curl -f http://localhost:3000/status || exit 1
ENTRYPOINT ["bin/openbox"]
CMD ["server"]

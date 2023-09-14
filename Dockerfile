FROM ruby:3.2.2-alpine3.17 as bundler

# Necessary for bundler to operate properly
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN gem install bundler

FROM bundler as dependencies

# The alpine way
RUN apk --no-cache update && apk --no-cache upgrade && \
  apk add --no-cache alpine-sdk automake zip unzip vim yarn \
  libtool libgomp libc6-compat openssl \
  curl build-base tzdata libtool nodejs bash bash-completion less\
  libffi libffi-dev tini tmux libxslt-dev libxml2-dev mysql mysql-client mysql-dev

# Set the timezone to America/Los_Angeles (Pacific) then get rid of tzdata
RUN cp -f /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
  echo 'America/Los_Angeles' > /etc/timezone

ARG UID=8083
ARG GID=8083

# Create an app user so our program doesn't run as root.
RUN addgroup -g "$GID" app && adduser -h /data -u "$UID" -G app -D -H app

FROM dependencies as gems

# Make sure the new user has complete control over all code, including
# bundler's installed assets
RUN mkdir -p /usr/local/bundle
RUN chown -R app:app /usr/local/bundle

# Pre-install gems so we aren't reinstalling all the gems when literally any
# filesystem change happens
RUN mkdir -p /data/build
RUN chown -R app:app /data && rm -rf /data/.cache
WORKDIR /data
COPY --chown=app:app Gemfile /data
COPY --chown=app:app Gemfile.lock /data
COPY --chown=app:app build/install_gems.sh /data/build
USER app
RUN /data/build/install_gems.sh

FROM gems as code

# Add the rest of the code
COPY --chown=app:app . /data

# Install node modules
RUN yarn install

ARG RAILS_ENV=${RAILS_ENV}
ENV RAILS_ENV=${RAILS_ENV}

FROM code

ENV DEPLOYED_VERSION=${DEPLOYED_VERSION}

RUN if [ "${RAILS_ENV}" = "production" ]; then \
  echo "Precompiling assets with $RAILS_ENV environment"; \
  rm -rf /data/.cache; \
  NODE_OPTIONS="--openssl-legacy-provider" RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=temporary bundle exec rails assets:precompile; \
  fi

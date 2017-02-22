FROM ruby:2.3.0-slim@sha256:8f3ae4ed9790a4b2c41a891deef876a204690b8d7c6bb8cf9ec060d3cf7903fd

WORKDIR /usr/src/app

# NOTE: libxml2-dev libxslt-dev for nokogiri (actionview 4.2 <- rails-html-sanitizer)
# NOTE: libffi-dev for ffi. see https://github.com/ffi/ffi/issues/485#issuecomment-191382158
# NOTE: gcc, g++ and libc-dev for json gem
# NOTE: linux-headers for raindrops gem
# NOTE: bash for ci
RUN mkdir -p /usr/src/app \
    && apt-get update \
    && apt-get install -y make python2.7 gcc g++ man curl git linux-headers-amd64 libffi-dev libxml2-dev libxslt-dev  \
    && ln -s /usr/bin/python2.7 /usr/bin/python \
    && curl -sL https://raw.githubusercontent.com/martinheidegger/install-node/master/install_node.sh | \
       NODE_VERSION="v5.1.0" \
       YARN_VERSION="v0.20.3" \
       bash \
    && rm -rf /var/cache/apk/* /var/lib/apt/lists/* /usr/share/doc /usr/share/perl* /usr/share/man || true

ADD entrypoint.sh /

ENTRYPOINT ["/bin/bash", "-l", "/entrypoint.sh"]

ONBUILD ADD package.json yarn.lock ./
ONBUILD RUN yarn install --no-emoji --ignore-optional --strict-semver --network-concurrency=15 --no-cache

ONBUILD ADD Gemfile* ./
ONBUILD RUN bundle install --jobs 4 --retry 3 --deployment --without test development cap machine \
            && rm -r vendor/bundle/ruby/*/cache


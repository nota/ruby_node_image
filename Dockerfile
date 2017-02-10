FROM python:2.7-alpine

WORKDIR /usr/src/app

# NOTE: libxml2-dev libxslt-dev for nokogiri (actionview 4.2 <- rails-html-sanitizer)
# NOTE: libffi-dev for ffi. see https://github.com/ffi/ffi/issues/485#issuecomment-191382158
# NOTE: gcc, g++ and libc-dev for json gem
# NOTE: linux-headers for raindrops gem
# NOTE: python 2.7 for node
# NOTE: bash for circleci
# NOTE: gnupg for installing node&yarn
RUN mkdir -p /usr/src/app \
    && apk update \
    && apk add make bash ruby ruby-io-console ruby-dev ruby-bigdecimal ruby-irb \
               gnupg gcc g++ man linux-headers libffi-dev libxml2-dev libxslt-dev curl git \
    && curl -sL https://raw.githubusercontent.com/martinheidegger/install-node/master/install_node.sh | \
       NODE_VERSION="v5.1.0" \
       YARN_VERSION="v0.19.1" \
       bash \
    && rm -rf /var/cache/apk/* /var/lib/apt/lists/* /usr/share/doc /usr/share/perl* /usr/share/man || true

ADD entrypoint.sh /
RUN    echo "export BUNDLE_PATH=/bundle"  >> /etc/profile \
    && echo "export PATH=\$PATH:/tmp/bin" >> /etc/profile

ENTRYPOINT ["/entrypoint.sh"]

ONBUILD ADD package.json yarn.lock ./
ONBUILD RUN yarn install --no-emoji --ignore-optional --strict-semver --network-concurrency=15 --no-cache

ONBUILD ADD Gemfile* ./
ONBUILD RUN bundle install --jobs 4 --retry 3 --deployment --without test development cap machine \
            && rm -r vendor/bundle/ruby/*/cache


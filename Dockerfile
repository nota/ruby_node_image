FROM ruby:2.3.0-slim@sha256:8f3ae4ed9790a4b2c41a891deef876a204690b8d7c6bb8cf9ec060d3cf7903fd

WORKDIR /usr/src/app

RUN mkdir -p /usr/src/app \
    && apt-get update \
    && apt-get install -y python2.7 gcc man curl git \
    && ln -s /usr/bin/python2.7 /usr/bin/python \
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


FROM node:8-slim

# Define build time arguments
ARG BUILD_DATE
ARG VCS_REF

# npm loglevel in base image is verbose, adjust to warnings only
ENV NPM_CONFIG_LOGLEVEL warn

# Set environment variables for tini GitHub repo
ENV TINI_VERSION=v0.18.0 \
    TINI_REPO=https://github.com/krallin/tini

# Set environment variables for reveal.js GitHub repo
ENV VERSION=3.6.0 \
    REPO=https://github.com/hakimel/reveal.js \
    SHA1=c044177d84e959c9c41edbb4dbc9b1dffa4b40d1

RUN set -ex \
    \
    && apt-get update \
    \
# Install necessary utilities
    && apt-get install -y --no-install-recommends bzip2 \
#    \
# Add tini for handling signals
# https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#handling-kernel-signals
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
    && wget -qO /bin/tini $TINI_REPO/releases/download/$TINI_VERSION/tini \
    && wget -qO /bin/tini.asc $TINI_REPO/releases/download/$TINI_VERSION/tini.asc \
    && gpg --verify /bin/tini.asc \
    && rm /bin/tini.asc \
    && chmod +x /bin/tini \
    \
# Fetch reveal.js
    && wget -qO /tmp/reveal.js.tar.gz $REPO/archive/$VERSION.tar.gz \
    && echo "$SHA1 /tmp/reveal.js.tar.gz" | sha1sum --check - \
    && tar -xzf /tmp/reveal.js.tar.gz -C / \
    && rm -f /tmp/reveal.js.tar.gz \
    && mv reveal.js-$VERSION reveal.js \
    \
# Install dependencies
    && mkdir -p /reveal.js/node_modules \
    && npm install -g grunt-cli \
    && npm install --prefix /reveal.js \
    \
# Clean up
    && rm -rf /tmp/npm* /tmp/phantomjs \
    && apt-get purge -y bzip2 \
    && rm -rf /var/lib/apt/lists/* \
    && chown -R node:node /reveal.js

WORKDIR /reveal.js

USER node

EXPOSE 8000

ENTRYPOINT ["tini", "--"]
CMD ["grunt", "serve"]

# Define image metadata (https://microbadger.com/labels)
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.license=MIT \
      org.label-schema.name="reveal.js" \
      org.label-schema.version=$VERSION \
      org.label-schema.url=https://github.com/hakimel/reveal.js \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/nbrownuk/docker-revealjs.git" \
      org.label-schema.vcs-type=Git

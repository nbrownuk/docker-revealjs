FROM node:4-alpine

# Define build time arguments
ARG BUILD_DATE
ARG VCS_REF

# npm loglevel in base image is verbose, adjust to warnings only
ENV NPM_CONFIG_LOGLEVEL warn

# Set environment variables for reveal.js GitHub repo
ENV VERSION=3.4.1 \
    REPO=https://github.com/hakimel/reveal.js \
    SHA1=64bf63c54e2a01ebcec905233527872940317426

RUN set -ex \
    \
# Add tini for handling signals
# https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#handling-kernel-signals
    && apk add --no-cache tini \
    \
# Install dependencies for fetching reveal.js source code
    && apk add --no-cache --virtual .fetch-deps \
        ca-certificates \
        tar \
        wget \
    \
# Fetch reveal.js
    && wget -qO /tmp/reveal.js.tar.gz $REPO/archive/$VERSION.tar.gz \
    && echo "$SHA1  /tmp/reveal.js.tar.gz" | sha1sum -c - \
    && tar -xzf /tmp/reveal.js.tar.gz -C / \
    && rm -f /tmp/reveal.js.tar.gz \
    && mv reveal.js-$VERSION reveal.js \
    \
# Install build tools
    && apk add --no-cache --virtual .build-deps \
        g++ \
        make \
        python \
    \
# Build and install dependencies
    && mkdir -p /reveal.js/node_modules \
    && npm install -g grunt-cli \
    && npm install --prefix /reveal.js \
    \
# Clean up
    && npm cache clean \
    && rm -rf /root/.node-gyp /tmp/npm* /tmp/phantomjs \
    && apk del .fetch-deps \
    && apk del .build-deps \
    && chown -R node:node /reveal.js

WORKDIR /reveal.js

USER node

EXPOSE 8000

ENTRYPOINT ["tini", "--"]
CMD ["grunt", "serve"]

# Define image metadata (https://microbadger.com/labels)
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/alpine/Dockerfile" \
      org.label-schema.license=MIT \
      org.label-schema.name="reveal.js" \
      org.label-schema.version=$VERSION \
      org.label-schema.url=https://github.com/hakimel/reveal.js \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/nbrownuk/docker-revealjs.git" \
      org.label-schema.vcs-type=Git

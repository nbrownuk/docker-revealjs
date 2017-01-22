FROM node:4-slim

MAINTAINER Nigel Brown <nigel@windsock.io>

# npm loglevel in base image is verbose, adjust to warnings only
ENV NPM_CONFIG_LOGLEVEL warn

# Add utilities for installation of dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        make \
        python \
        bzip2 \
        wget && \
    rm -rf /var/lib/apt/lists/*

# Add tini as PID 1 to facilitate correct signal handling
# See https://github.com/nodejs/node-v0.x-archive/issues/9131
ENV TINI_VERSION=v0.10.0 \
    TINI_REPO=https://github.com/krallin/tini
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 && \
    wget -qO /bin/tini $TINI_REPO/releases/download/$TINI_VERSION/tini && \
    wget -qO /bin/tini.asc $TINI_REPO/releases/download/$TINI_VERSION/tini.asc && \
    gpg --verify /bin/tini.asc && \
    rm /bin/tini.asc && \
    chmod +x /bin/tini

# Retrieve reveal.js from Github repsoitory
ENV VERSION=3.4.0 \
    REPO=https://github.com/hakimel/reveal.js \
    SHA=40b130154495620cb9970f0ab893f1cf00b0571d
RUN wget -qO /tmp/reveal.js.tar.gz $REPO/archive/$VERSION.tar.gz && \
    echo "$SHA /tmp/reveal.js.tar.gz" | sha1sum --check - && \
    tar -xzf /tmp/reveal.js.tar.gz -C / && \
    rm -f /tmp/reveal.js.tar.gz && \
    mv reveal.js-$VERSION reveal.js

# Set working directory for container
WORKDIR /reveal.js

# Create user, install grunt CLI and dependencies, and set ownership
RUN useradd -r revealjs && \
    npm install -g grunt-cli && \
    npm install && \
    npm cache clean && \
    rm -rf /tmp/npm* && \
    chown -R revealjs:revealjs /reveal.js

# Set user
USER revealjs

# Expose default port
EXPOSE 8000

# Add script for processing runtime configuration options
COPY docker-entrypoint.sh /entrypoint.sh

# Add container entrypoint
ENTRYPOINT ["/bin/tini", "--", "/entrypoint.sh"]

# Add presentation data (index.html, slides.md, media/*)
ONBUILD COPY index.html ./
ONBUILD COPY md/ ./md/
ONBUILD COPY media/ ./media/

# Add customisations (see https://github.com/hakimel/reveal.js#folder-structure)
ONBUILD COPY css/ ./css/
ONBUILD COPY js/ ./js/
ONBUILD COPY plugin/ ./plugin/
ONBUILD COPY lib/ ./lib/

# Provide image labels in support of the Label Schema (http://label-schema.org)
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.license="MIT" \
      org.label-schema.version="3.4.0" \
      org.label-schema.url="https://github.com/hakimel/reveal.js" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/nbrownuk/docker-revealjs.git" \
      org.label-schema.vcs-type="Git"

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
        wget && \
    rm -rf /var/lib/apt/lists/*

# Add tini as PID 1 to facilitate correct signal handling
# See https://github.com/nodejs/node-v0.x-archive/issues/9131
ENV TINI_VERSION        v0.9.0
ENV TINI_REPO           https://github.com/krallin/tini
ENV TINI_SHA            e00bce884edb1d94a5fcf2423ee92dc05ddce926
RUN wget -qO /bin/tini $TINI_REPO/releases/download/$TINI_VERSION/tini && \
    echo "$TINI_SHA /bin/tini" | sha1sum --check - && \
    chmod +x /bin/tini

# Retrieve reveal.js from Github repsoitory
ENV VERSION             3.2.0
ENV REPO                https://github.com/hakimel/reveal.js
ENV SHA                 5230106c9cd86da14bb186d4ef41fec2f3e822dd
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

FROM node:0.10.40-slim

MAINTAINER Nigel Brown <nigel@windsock.io>

# npm loglevel in base image is verbose, adjust to warnings only
ENV NPM_CONFIG_LOGLEVEL warn

# Add utilities for installation of dependencies
RUN apt-get update && \
    apt-get install -y --install-recommends \
        g++ \
        make \
        python \
        wget && \
    rm -rf /var/lib/apt/lists/*

# Add tini as PID 1 to facilitate correct signal handling
# See https://github.com/nodejs/node-v0.x-archive/issues/9131
ENV TINI_VERSION        v0.8.2
ENV TINI_REPO           https://github.com/krallin/tini
ENV TINI_SHA            48bfa00a11481f9894be98e859578e1098195077
RUN wget -qO /bin/tini $TINI_REPO/releases/download/$TINI_VERSION/tini && \
    echo "$TINI_SHA /bin/tini" | sha1sum --check - && \
    chmod +x /bin/tini

# Retrieve reveal.js from Github repsoitory & set ownership
ENV VERSION             3.1.0
ENV REPO                https://github.com/hakimel/reveal.js
ENV SHA                 b436b7793c0c11cfe446822d8729ae3c64ae883d
RUN wget -qO /tmp/reveal.js.tar.gz $REPO/archive/$VERSION.tar.gz && \
    echo "$SHA /tmp/reveal.js.tar.gz" | sha1sum --check - && \
    tar -xzf /tmp/reveal.js.tar.gz -C / && \
    rm -f /tmp/reveal.js.tar.gz && \
    mv reveal.js-$VERSION reveal.js && \
    useradd -r revealjs

# Set working directory for container
WORKDIR /reveal.js

# Install the grunt CLI and install dependencies
RUN npm install -g grunt-cli && \
    npm install && \
    npm cache clean && \
    rm -rf /tmp/npm* && \
    chown -R revealjs:revealjs /reveal.js

# Set user
USER revealjs

# Expose default port
EXPOSE 8000

# Add container entrypoint and default arguments
CMD ["grunt", "serve"]
ENTRYPOINT ["/bin/tini", "--"]

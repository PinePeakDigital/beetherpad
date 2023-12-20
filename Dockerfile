
FROM etherpad/etherpad

# Copy the plugin folder to the container
COPY ep_simple_urls /ep_simple_urls

# Install dependencies
USER root
RUN cd /opt/etherpad-lite/src && \
    # npm install --no-save --legacy-peer-deps /ep_simple_urls
    npm install --no-save --legacy-peer-deps ep_post_data
    # npm install /ep_simple_urls
USER etherpad


FROM etherpad/etherpad

RUN cd /opt/etherpad-lite/src && \
    npm install --no-save --legacy-peer-deps ep_post_data

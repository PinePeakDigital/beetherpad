
FROM etherpad/etherpad:1.9.6

COPY ep_simple_urls /ep_simple_urls

RUN cd /opt/etherpad-lite && \
    npm install /ep_simple_urls


FROM etherpad/etherpad:1.9.6

WORKDIR /opt/etherpad-lite

COPY robots.txt ./src/static/robots.txt

COPY settings.json ./settings.json

COPY ep_simple_urls /ep_simple_urls

RUN npm install /ep_simple_urls

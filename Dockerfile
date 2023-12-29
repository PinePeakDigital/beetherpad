
FROM etherpad/etherpad:1.9.6

WORKDIR /opt/etherpad-lite

RUN npm install \
    ep_adminpads3 \
    ep_author_hover \
    ep_brightcolorpicker \
    ep_pad_activity_nofication_in_title \
    ep_post_data \
    ep_prompt_for_name \
    ep_sync_status

COPY robots.txt ./src/static/robots.txt
COPY settings.json ./settings.json
COPY ep_simple_urls /ep_simple_urls

RUN npm install /ep_simple_urls

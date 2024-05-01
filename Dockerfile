
FROM etherpad/etherpad:2.0.2

WORKDIR /opt/etherpad-lite/src

RUN pnpm install \
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

RUN pnpm install /ep_simple_urls

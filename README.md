# beetherpad

## Initial Local Setup

```bash
git submodule update --init --recursive
cp .env.example .env # edit .env as needed
echo "127.0.0.1 secretdomain" | sudo tee -a /etc/hosts
```

## Local Usage

```bash
./docker-down.sh # to ensure nothing is already running
./docker-up.sh
open http://localhost:9001 # xdg-open on GNU/Linux machines
open http://secretdomain:9001 # xdg-open on GNU/Linux machines
docker restart beetherpad # to load plugin changes
```

## Socket Buffer Size Limit

Etherpad limits the socket buffer size to guard against DoS attacks.
If you find that large updates to documents aren't being saved, you
may need to increase the socket buffer size limit. This can be done
by changing the `socketIo.maxHttpBufferSize` setting in `settings.json`
here in GitHub and allowing the Etherpad instance to redeploy.

Reference:

- [Etherpad keeps reconnecting after pasting large text](https://github.com/ether/etherpad-lite/issues/4951)

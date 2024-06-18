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

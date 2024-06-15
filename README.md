# beetherpad

## Building for Development

Pull the submodules.

```bash
git submodule update --init --recursive
```

Build and start the beetherpad and postgres containers.

```bash
DEV_ENV=true ETHERPAD_SECRET_DOMAIN=localhost ./docker-up.sh
open http://localhost:9001 # xdg-open on GNU/Linux machines
```

For ease of development, `docker-up.sh` mounts the local plugin
directories into the running beetherpad container. After you modify a
local plugin, restart the beetherpad container to load your changes.

```bash
docker restart beetherpad
```

Setting `ETHERPAD_SECRET_DOMAIN` to `localhost` leaves you with no way
to access the public routes on your development machine. If that's a
problem, you'll need to modify your hosts file to add a new domain to
use as the secret domain.

```
127.0.0.1 secretdomain
```

Then rebuild your container with your secret domain.

```bash
./docker-down.sh # stop your containers if they were running
DEV_ENV=true ETHERPAD_SECRET_DOMAIN=secretdomain ./docker-up.sh
open http://localhost:9001 # xdg-open on GNU/Linux machines
```

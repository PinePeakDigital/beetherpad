# beetherpad

```bash
ETHERPAD_SECRET_DOMAIN=fake DEV_ENV=true ./docker-up.sh # simulate public etherpad url
ETHERPAD_SECRET_DOMAIN=localhost DEV_ENV=true ./docker-up.sh # simulate secret etherpad url
open http://localhost:9001
./docker-down.sh
```

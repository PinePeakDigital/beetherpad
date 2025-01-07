# beetherpad

A customized Etherpad instance with plugins for URL simplification and post data handling.

## Initial Local Setup

```bash
# Clone and setup submodules
git submodule update --init --recursive

# Setup environment
cp .env.example .env # edit .env as needed
echo "127.0.0.1 secretdomain" | sudo tee -a /etc/hosts

# Install dependencies
pnpm install
```

## Local Development

```bash
# Stop any running instances
./docker-down.sh

# Start the development server
./docker-up.sh

# Access the application
open http://localhost:9001
open http://secretdomain:9001

# Reload plugins after changes
docker restart beetherpad
```

## Testing

```bash
# Run tests for ep_simple_urls plugin
cd ep_simple_urls && pnpm test

# Visual regression tests
cd scripts/puppeteer && pnpm test
```

## Configuration

### Socket Buffer Size
Etherpad limits the socket buffer size to guard against DoS attacks.
If you find that large updates to documents aren't being saved, you
may need to increase the socket buffer size limit. This can be done
by changing the `socketIo.maxHttpBufferSize` setting in `settings.json`.

### Environment Variables
Key environment variables:
- `DB_TYPE`: Database type (postgres/dirty)
- `ADMIN_PASSWORD`: Admin user password
- `ETHERPAD_SECRET_DOMAIN`: Secret domain for special access

## Deployment
Deployments are automated via GitHub Actions to Render.com when changes are pushed to main.

## Contributing
1. Create a feature branch
2. Make changes
3. Run tests
4. Submit a pull request

For more details, see [knowledge.md](knowledge.md).

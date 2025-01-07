# ep_simple_urls

A plugin for Etherpad that provides URL simplification and management features.

## Features
- URL rewriting for cleaner pad URLs
- Custom domain support
- Secure domain restrictions
- Export button integration

## Installation
```bash
npm install ep_simple_urls
```

## Configuration
Add to your Etherpad's settings.json:
```json
{
  "ep_simple_urls": {
    "secretDomain": "your-domain.com"
  }
}
```

## Development
```bash
# Install dependencies
pnpm install

# Run tests
pnpm test
```

## API
The plugin provides hooks for:
- URL rewriting (expressPreSession)
- Socket.io security
- UI customization (editbar buttons)

# Beetherpad Knowledge

## Project Overview
A customized Etherpad instance with plugins for URL simplification and post data handling.

## Key Components
- ep_simple_urls: Plugin for URL management and redirection
- ep_post_data: Plugin for handling post data
- ep_pad_activity_nofication_in_title: Plugin for activity notifications

## Development Guidelines
- Use pnpm as the package manager
- Node version: 20.9.0 (see .nvmrc)
- Run tests before committing changes
- Keep socket.io security restrictions in place
- Test both PostgreSQL and dirty db configurations

## Testing
- Run plugin tests individually in their directories
- Use puppeteer tests for visual regression testing
- Test URL rewrites with various domain configurations

## Configuration
- Socket buffer size limit can be adjusted in settings.json via socketIo.maxHttpBufferSize
- Database can be either PostgreSQL or dirty db (development)
- Environment variables control most settings
- Secret domain must be configured for URL rewriting

## Deployment
- Uses GitHub Actions for CI/CD
- Deploys to Render.com
- Requires PostgreSQL database in production
- Automated visual regression testing before deploy

## Security Guidelines
- Always maintain socket.io restrictions
- Keep plugin management disabled in production
- Use environment variables for sensitive data
- Validate domains in URL rewriting

## URLs and References
- [Etherpad Documentation](https://etherpad.org/doc/latest/)
- [PostgreSQL Setup](https://www.postgresql.org/docs/current/admin.html)
- [Render.com Deployment](https://render.com/docs)

# Database Configuration

## Container Management

- You may wish to verify container status before operations: `docker ps`
- Both containers must be running: `beetherpad-postgres` and `beetherpad`
- Use `docker-up.sh` to start containers
- Use `docker-down.sh` to stop containers
- If containers fail to start, check logs: `docker logs beetherpad`

## Development Environment

- Uses Docker container named `beetherpad-postgres`
- Database host automatically set to container name
- Database host can be overridden with the `DB_HOST` variable in your `.env`
- Default credentials in `.env.sample`

## Production Environment

- Requires proper DB_HOST environment variable
- Must set database credentials via environment variables
- Check settings.json for all database configuration options

## Common Issues

- ENOTFOUND may indicate incorrect database host configuration
- Unclean exits may occur if database connections aren't properly closed
- Set DUMP_ON_UNCLEAN_EXIT=true to debug shutdown issues

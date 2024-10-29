# Authentication System

## Overview

- Uses basic authentication for admin access
- Requires both URL routing and proper authentication setup
- Admin authentication handled through `/admin-auth` endpoint

## Common Issues

- 401 Unauthorized response on /admin-auth may indicate cookie and cookie security issues.
- Ensure Postgress ENVs do not conflict with other environment variables in your .env

## Configuration

- Authentication routes must be excluded from URL rewriting
- Both admin and admin-auth paths must be properly handled

## Security Notes

- Admin interface should only be accessible on secret domain
- Avoid exposing admin routes on public domain

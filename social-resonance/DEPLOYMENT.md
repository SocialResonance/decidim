# Social Resonance Deployment Guide

This guide explains how to deploy the Social Resonance Decidim application using Coolify. The app is now integrated into the main Decidim repository structure.

## Repository Structure

```
/decidim/
├── decidim-core/
├── decidim-admin/
├── decidim-ai/
├── decidim-collaborative_texts/
├── social-resonance/           ← Your app here
│   ├── Dockerfile (multi-stage: development & production)
│   ├── docker-compose.development.yml
│   ├── docker-compose.production.yml
│   ├── Gemfile (with local path dependencies)
│   └── ...
└── ...
```

## Prerequisites

### For Production Deployment
1. **Coolify Instance**: Self-hosted or cloud
2. **Managed Services**: PostgreSQL and Redis in Coolify
3. **Domain Names**:
   - Staging: `staging.yourdomain.com`
   - Production: `production.yourdomain.com`

### For Local Development
1. **Docker & Docker Compose**: Installed locally
2. **PostgreSQL**: Running locally (uncontainerized)
3. **Redis**: Running locally (uncontainerized)
4. **Git Repository**: Cloned with all Decidim modules

## Local Development Setup

### 1. Start Local Services
Make sure PostgreSQL and Redis are running locally:

```bash
# macOS with Homebrew
brew services start postgresql
brew services start redis

# Or using your preferred method
```

### 2. Run with Docker Compose
```bash
cd social-resonance
docker-compose -f docker-compose.development.yml up --build
```

This will:
- Build the development container
- Connect to your local PostgreSQL and Redis
- Mount source code for live reloading
- Start the web server and Sidekiq workers

### 3. Setup Database
```bash
# Create and migrate database
docker-compose -f docker-compose.development.yml exec web bundle exec rails db:create db:migrate

# Seed with sample data (optional)
docker-compose -f docker-compose.development.yml exec web bundle exec rails db:seed
```

### 4. Access Application
- **Web**: http://localhost:3000
- **Logs**: `docker-compose -f docker-compose.development.yml logs -f`

## Production Deployment Steps

### 1. Set Up Managed Services in Coolify

Create these managed services first:

1. **PostgreSQL Database**:
   - Create new PostgreSQL service
   - Note the `DATABASE_URL` for environment variables

2. **Redis Cache**:
   - Create new Redis service
   - Note the `REDIS_URL` for environment variables

### 2. Create Application in Coolify

1. **Create New Resource** → **Application**
2. **Connect Git Repository**: Your Decidim repository (with social-resonance inside)
3. **Build Settings**:
   - **Build Pack**: Docker
   - **Dockerfile**: `social-resonance/Dockerfile`
   - **Docker Compose File**: `social-resonance/docker-compose.production.yml`
   - **Build Context**: Repository root (not social-resonance subdirectory)
   - **Build Target**: `production` (for multi-stage build)

### 3. Environment Variables

Set these in Coolify for your application:

#### Core Application
```bash
# Rails
RAILS_MASTER_KEY=your_master_key_here
SECRET_KEY_BASE=your_secret_key_base_here
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_LEVEL=warn  # info for staging, warn for production

# Database (from Coolify managed PostgreSQL)
DATABASE_URL=postgresql://user:password@host:port/database

# Redis (from Coolify managed Redis)
REDIS_URL=redis://host:port/database
```

#### Email Configuration
```bash
SMTP_ADDRESS=your.smtp.server.com
SMTP_PORT=587
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password
SMTP_DOMAIN=yourdomain.com
SMTP_STARTTLS_AUTO=true
```

#### Decidim Configuration
```bash
DECIDIM_APPLICATION_NAME=Social Resonance
DECIDIM_MAILER_SENDER=noreply@yourdomain.com
DECIDIM_DEFAULT_LOCALE=en
DECIDIM_AVAILABLE_LOCALES=en,ca,es
DECIDIM_FORCE_SSL=true
```

#### Storage (S3 Recommended for Production)
```bash
STORAGE_PROVIDER=s3
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_BUCKET=your-bucket-name
AWS_REGION=us-east-1
```

#### Maps (Optional)
```bash
MAPS_PROVIDER=here
MAPS_API_KEY=your_maps_api_key
```

#### Performance
```bash
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=4
SIDEKIQ_CONCURRENCY=10
QUEUE_ADAPTER=sidekiq
```

### 4. Domain & SSL Configuration

1. **Set Custom Domain** in Coolify
2. **Enable SSL** (Let's Encrypt)
3. **Configure DNS** to point to your Coolify server

### 5. Post-Deployment Setup

#### 5.1 Create System Admin
```bash
# In Coolify terminal for your app container
cd /workspace/social-resonance
bundle exec rails decidim_system:create_admin
```

#### 5.2 Create Organization
1. Visit `https://yourdomain.com/system`
2. Log in with system admin credentials
3. Create new organization
4. Set the correct host (include subdomain if any)
5. Configure locales and other settings

## Features Available

With this merged approach, you have access to:

- ✅ **All core Decidim modules** (proposals, meetings, assemblies, budgets, etc.)
- ✅ **Unpublished modules**: `decidim-ai`, `decidim-collaborative_texts`, `decidim-design`
- ✅ **Community modules**: `decidim-calendar`, `decidim-decidim_awesome`
- ✅ **Latest development features**
- ✅ **Custom modifications** to Decidim core if needed

## Services Deployed

The deployment includes:

1. **Web Application**: Main Rails app serving HTTP requests
2. **Sidekiq Workers**: Background job processing
3. **Cron Jobs**: Scheduled maintenance tasks:
   - Remove expired download files (daily)
   - Export open data (daily)
   - Clean old registration forms (daily)
   - Generate reminders (daily)
   - Send notification digest (daily)

## Monitoring

- **Application Health**: `https://yourdomain.com/health`
- **Coolify Dashboard**: Monitor all services
- **Logs**: Access through Coolify interface

## Environment Differences

| Setting | Staging | Production |
|---------|---------|------------|
| App Name | `Social Resonance Staging` | `Social Resonance` |
| Storage | `local` | `s3` |
| Log Level | `info` | `warn` |
| SSL | Required | Required |

## Troubleshooting

### Common Issues

1. **Build Failures**: Check that Dockerfile paths are correct
2. **Database Connection**: Verify `DATABASE_URL` from managed PostgreSQL
3. **Asset Issues**: Ensure assets precompile correctly during build
4. **Module Loading**: All local path dependencies should resolve automatically

### Logs
- **Build Logs**: Check Docker build process in Coolify
- **Application Logs**: Check Rails logs through Coolify
- **Background Jobs**: Monitor Sidekiq queues

## Security Checklist

- [ ] SSL enabled with valid certificate
- [ ] Strong database passwords (managed by Coolify)
- [ ] Secure SMTP credentials
- [ ] S3 bucket with proper permissions
- [ ] Environment variables secured in Coolify
- [ ] System admin account with strong password

## Support

- **Decidim Documentation**: https://docs.decidim.org
- **Coolify Documentation**: https://coolify.io/docs
- **Community Support**: Decidim GitHub discussions

# Deploying Social-Resonance (Decidim) to Staging and Production on Coolify

## Overview

This guide explains how to deploy the social-resonance project (which is based on Decidim - a participatory democracy framework built with Ruby on Rails) to both staging and production environments using Coolify. Coolify is a self-hosted PaaS (Platform as a Service) that simplifies application deployment with features similar to Heroku, Vercel, or Netlify.

## What is Coolify?

Coolify is an open-source, self-hostable platform that provides:
- Automated deployments from Git repositories
- SSL certificate management (Let's Encrypt)
- Environment management (staging, production, etc.)
- Container orchestration
- Database backups
- Monitoring and notifications
- Support for multiple deployment methods (Docker, Nixpacks, etc.)

## Prerequisites

1. **Coolify Instance**: Either self-hosted or using Coolify Cloud ($48/year for 2 servers)
2. **Server Infrastructure**: VPS or dedicated server (e.g., Hetzner, DigitalOcean, AWS)
3. **Domain Names**: Separate domains/subdomains for staging and production
4. **Git Repository**: Your social-resonance project in GitHub/GitLab/Bitbucket

## Setting Up Coolify

### 1. Install Coolify (Self-Hosted)

```bash
wget -q https://get.coollabs.io/coolify/install.sh -O install.sh
sudo bash ./install.sh
```

Access Coolify at `http://your-server-ip:3000` and create your admin account.

### 2. Configure Your Server

1. Create an SSH key in Coolify
2. Add the SSH key to your server
3. Connect your server to Coolify

## Deploying Decidim to Coolify

### Step 1: Create a Project Structure

In Coolify, organize your deployments:

```
Project: Social Resonance
├── Environment: Production
│   ├── Application: social-resonance-app
│   ├── Database: PostgreSQL
│   └── Redis: Cache (optional)
└── Environment: Staging
    ├── Application: social-resonance-staging-app
    ├── Database: PostgreSQL (staging)
    └── Redis: Cache (optional)
```

### Step 2: Prepare Your Decidim Application

1. **Create a Dockerfile** in your project root:

```dockerfile
FROM decidim/decidim:latest

# Install additional dependencies if needed
RUN apt-get update && apt-get install -y \
    build-essential \
    postgresql-client \
    nodejs \
    yarn

# Copy application code
COPY . /app
WORKDIR /app

# Install Ruby dependencies
RUN bundle install --without development test

# Precompile assets
RUN RAILS_ENV=production bundle exec rake assets:precompile

# Set the start command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "${PORT:-3000}", "-e", "$RAILS_ENV"]
```

2. **Create docker-compose.yml** (optional, for local testing):

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://decidim:password@db:5432/decidim_production
      - REDIS_URL=redis://redis:6379
      - RAILS_ENV=production
    depends_on:
      - db
      - redis
  
  db:
    image: postgres:14
    environment:
      - POSTGRES_USER=decidim
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=decidim_production
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:7-alpine

volumes:
  postgres_data:
```

### Step 3: Configure Environments in Coolify

#### Production Environment Setup

1. **Create Production Resources**:
   - Navigate to your project in Coolify
   - Select "Production" environment
   - Click "Add New Resource"

2. **Deploy PostgreSQL Database**:
   - Choose "Database" → "PostgreSQL"
   - Configure:
     - Name: `social-resonance-db-prod`
     - PostgreSQL version: 14 or higher
     - Set strong passwords
     - Enable automatic backups to S3

3. **Deploy Redis (Optional)**:
   - Choose "Database" → "Redis"
   - Name: `social-resonance-redis-prod`

4. **Deploy the Application**:
   - Choose your Git repository method
   - Configure build settings:
     ```
     Build Pack: Dockerfile
     Dockerfile Location: /Dockerfile
     Port: 3000
     ```

5. **Set Production Environment Variables**:
   ```bash
   RAILS_ENV=production
   SECRET_KEY_BASE=<generate-secure-key>
   DATABASE_URL=postgresql://user:pass@social-resonance-db-prod:5432/decidim
   REDIS_URL=redis://social-resonance-redis-prod:6379
   RAILS_SERVE_STATIC_FILES=true
   RAILS_LOG_TO_STDOUT=true
   
   # Decidim specific
   DECIDIM_APPLICATION_NAME="Social Resonance"
   DECIDIM_MAILER_SENDER=noreply@yourdomain.com
   DECIDIM_AVAILABLE_LOCALES=en,es,fr
   
   # SMTP Configuration
   SMTP_ADDRESS=smtp.yourdomain.com
   SMTP_PORT=587
   SMTP_DOMAIN=yourdomain.com
   SMTP_USER_NAME=smtp-user
   SMTP_PASSWORD=smtp-password
   ```

6. **Configure Domain**:
   - Set custom domain: `social-resonance.yourdomain.com`
   - Coolify will automatically handle SSL certificates

#### Staging Environment Setup

1. **Duplicate Production Setup**:
   - Create similar resources in the "Staging" environment
   - Use different names with `-staging` suffix

2. **Staging-Specific Variables**:
   ```bash
   RAILS_ENV=staging
   DATABASE_URL=postgresql://user:pass@social-resonance-db-staging:5432/decidim_staging
   DECIDIM_APPLICATION_NAME="Social Resonance (Staging)"
   # Use staging subdomain
   ```

3. **Configure Staging Domain**:
   - Set domain: `staging.social-resonance.yourdomain.com`

### Step 4: Database Migrations

For Ruby on Rails applications like Decidim, configure the start command to run migrations:

```bash
bundle exec rake db:migrate && bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000} -e $RAILS_ENV
```

### Step 5: Configure Automated Deployments

1. **Production Branch**:
   - Set up webhook for `main` or `production` branch
   - Enable "Auto Deploy" in Coolify

2. **Staging Branch**:
   - Configure webhook for `develop` or `staging` branch
   - Enable "Auto Deploy" for staging environment

### Step 6: Set Up Backups

1. **Configure S3 Storage** (e.g., Backblaze B2, AWS S3):
   - Go to "S3 Storages" in Coolify
   - Add your S3 credentials

2. **Enable Database Backups**:
   - In each PostgreSQL resource
   - Configure backup schedule (e.g., daily)
   - Select your S3 storage

## Advanced Configuration

### Environment-Specific Settings

Use Coolify's environment variables feature to manage different configurations:

```bash
# Production
{{environment.NODE_ENV}}=production
{{environment.ENABLE_DEBUG}}=false

# Staging  
{{environment.NODE_ENV}}=staging
{{environment.ENABLE_DEBUG}}=true
```

### Health Checks

Configure health checks for your Decidim application:

```yaml
# In Coolify settings
Health Check Path: /health_check
Health Check Interval: 30s
Health Check Timeout: 10s
```

### Resource Limits

Set appropriate resource limits:

```yaml
# Production
CPU: 2 cores
Memory: 4GB

# Staging
CPU: 1 core
Memory: 2GB
```

### Monitoring and Alerts

1. Enable Coolify monitoring
2. Configure notifications:
   - Discord/Slack webhooks
   - Email alerts
   - Telegram notifications

## Deployment Workflow

### 1. Initial Deployment

```bash
# Production
git checkout main
git push origin main
# Coolify auto-deploys to production

# Staging
git checkout develop
git push origin develop
# Coolify auto-deploys to staging
```

### 2. Continuous Deployment

1. **Feature Development**:
   ```bash
   git checkout -b feature/new-feature
   # Make changes
   git push origin feature/new-feature
   # Create PR to develop branch
   ```

2. **Staging Deployment**:
   - Merge PR to `develop`
   - Coolify automatically deploys to staging

3. **Production Deployment**:
   - After testing in staging
   - Merge `develop` to `main`
   - Coolify automatically deploys to production

## Troubleshooting

### Common Issues

1. **Database Connection Issues**:
   - Check DATABASE_URL format
   - Verify network connectivity between containers
   - Check PostgreSQL logs

2. **Asset Compilation Errors**:
   - Ensure NODE_ENV is set correctly
   - Check available memory during build
   - Review build logs in Coolify

3. **SSL Certificate Issues**:
   - Verify DNS records point to Coolify server
   - Check domain configuration in Coolify
   - Wait for DNS propagation

### Debugging Commands

Access container terminal through Coolify's web interface:

```bash
# Check Rails console
bundle exec rails console

# Run migrations manually
bundle exec rake db:migrate

# Check logs
tail -f log/production.log
```

## Best Practices

1. **Security**:
   - Use strong passwords for databases
   - Rotate SECRET_KEY_BASE regularly
   - Keep staging and production environments isolated

2. **Performance**:
   - Enable caching with Redis
   - Use CDN for static assets
   - Monitor resource usage

3. **Backup Strategy**:
   - Daily automated backups
   - Test restore procedures regularly
   - Keep backups in different regions

4. **Deployment Strategy**:
   - Always test in staging first
   - Use pull request previews for features
   - Implement proper rollback procedures

## Cost Considerations

- **Coolify Cloud**: $48/year for 2 servers
- **Self-hosted**: Free (requires your own server)
- **Server costs**: 
  - Staging: $10-15/month (small VPS)
  - Production: $30-50/month (dedicated resources)
- **Backup storage**: ~$5/month for S3-compatible storage

## Conclusion

Coolify provides an excellent platform for deploying Decidim applications with separate staging and production environments. Its Git-based deployment, automatic SSL, and environment management features make it ideal for teams looking for Heroku-like simplicity with self-hosted control.

Key advantages:
- No vendor lock-in
- Cost-effective compared to PaaS alternatives
- Full control over your infrastructure
- Automated deployments and SSL management
- Built-in backup and monitoring features

For the social-resonance project, this setup provides a professional deployment pipeline with minimal operational overhead.
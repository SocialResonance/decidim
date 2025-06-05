# Coolify Deployment Guide for Social Resonance

This guide explains how to deploy the Social Resonance Decidim application to both staging and production environments using Coolify.

**Note**: This deployment uses the full Decidim repository (including all modules) to access unpublished modules like `decidim-ai`, `decidim-collaborative_texts`, and `decidim-design`.

## Prerequisites

1. **Coolify Instance**: You need access to a Coolify instance (self-hosted or cloud)
2. **Git Repository**: Your code should be in a Git repository (GitHub, GitLab, etc.)
3. **Domain Names**:
   - Staging: `staging.yourdomain.com`
   - Production: `production.yourdomain.com` or `yourdomain.com`

## Deployment Steps

### 1. Create Applications in Coolify

1. **Log into Coolify**
2. **Create New Resource** → **Application**
3. **Connect your Git repository** (this should be the entire Decidim repository)
4. **Set the Build Context** to the root directory (not just social-resonance)
5. **Select the branch**:
   - Staging: `develop` or `staging` branch
   - Production: `main` or `master` branch

### 2. Set Up Managed Services

Before deploying the application, create these managed services in Coolify:

1. **PostgreSQL Database**:
   - Create a new PostgreSQL service
   - Note the connection URL for environment variables

2. **Redis Cache**:
   - Create a new Redis service
   - Note the connection URL for environment variables

### 3. Configure Build Settings

For both staging and production:
- **Build Pack**: Docker
- **Dockerfile**: `social-resonance/Dockerfile.production`
- **Docker Compose File**: `social-resonance/docker-compose.production.yml`

### 4. Environment Variables

#### Required Environment Variables

Set these environment variables in Coolify for each environment:

##### Core Application
```bash
# Rails
RAILS_MASTER_KEY=your_master_key_here
SECRET_KEY_BASE=your_secret_key_base_here
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_LEVEL=info  # info for staging, warn for production

# Database (from Coolify managed PostgreSQL)
DATABASE_URL=postgresql://user:password@host:port/database

# Redis (from Coolify managed Redis)
REDIS_URL=redis://host:port/database
```

##### Email Configuration
```bash
SMTP_ADDRESS=your.smtp.server.com
SMTP_PORT=587
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password
SMTP_DOMAIN=yourdomain.com
SMTP_STARTTLS_AUTO=true
```

##### Decidim Configuration
```bash
DECIDIM_APPLICATION_NAME=Social Resonance  # Add "Staging" for staging
DECIDIM_MAILER_SENDER=noreply@yourdomain.com
DECIDIM_DEFAULT_LOCALE=en
DECIDIM_AVAILABLE_LOCALES=en,ca,es
DECIDIM_FORCE_SSL=true
```

##### Storage (Production - S3 Recommended)
```bash
STORAGE_PROVIDER=s3  # local for staging, s3 for production
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_BUCKET=your-bucket-name
AWS_REGION=us-east-1
```

##### Maps (Optional)
```bash
MAPS_PROVIDER=here  # or osm
MAPS_API_KEY=your_maps_api_key
```

##### Performance
```bash
RAILS_MAX_THREADS=5
WEB_CONCURRENCY=2  # 2 for staging, 4 for production
SIDEKIQ_CONCURRENCY=5  # 5 for staging, 10 for production
QUEUE_ADAPTER=sidekiq
```

### 5. Domain Configuration

1. **Set Custom Domain** in Coolify
2. **Enable SSL** (Let's Encrypt)
3. **Configure DNS** to point to your Coolify server

### 6. Post-Deployment Setup

After successful deployment, you need to:

#### 6.1 Create System Admin
```bash
# In Coolify terminal for your app container
bundle exec rails decidim_system:create_admin
```

#### 6.2 Create Organization
1. Visit `https://yourdomain.com/system`
2. Log in with system admin credentials
3. Create new organization
4. Set the correct host (include subdomain if any)
5. Configure locales and other settings

## Environment Differences

| Setting | Staging | Production |
|---------|---------|------------|
| Rails Environment | `production` | `production` |
| Application Name | `Social Resonance Staging` | `Social Resonance` |
| Database Name | `social_resonance_staging` | `social_resonance_production` |
| Storage Provider | `local` | `s3` |
| Log Level | `info` | `warn` |
| Web Concurrency | `2` | `4` |
| Sidekiq Concurrency | `5` | `10` |

## Scheduled Tasks

The production deployment includes a cron container that runs essential Decidim maintenance tasks:
- Remove expired download files (daily at midnight)
- Export open data (daily at 00:02)
- Clean old registration forms (daily at 00:03)
- Generate reminders (daily at 00:04)
- Send notification digest (daily at 00:05)

## Monitoring

Use Coolify's built-in monitoring or add these health checks:
- Application: `https://yourdomain.com/health`
- Database: Check PostgreSQL connection
- Redis: Check Redis connection
- Background Jobs: Monitor Sidekiq queues

## Backup Strategy

### Database Backups
Configure automatic PostgreSQL backups in Coolify or set up external backup solution.

### File Storage Backups
- **Local Storage**: Back up the `uploads` volume
- **S3 Storage**: Enable S3 versioning and backup

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   - Check `DATABASE_URL` or individual DB environment variables
   - Ensure PostgreSQL service is running

2. **Asset Compilation Issues**
   - Verify Node.js version compatibility
   - Check if all dependencies are installed

3. **Email Delivery Issues**
   - Verify SMTP credentials
   - Check firewall rules for SMTP port

4. **SSL Certificate Issues**
   - Ensure domain DNS points to Coolify server
   - Check Let's Encrypt rate limits

### Logs
Access logs through Coolify interface:
- Application logs: Check Rails logs
- Build logs: Check Docker build process
- System logs: Check container health

## Security Checklist

- [ ] SSL enabled with valid certificate
- [ ] Strong database passwords
- [ ] Secure SMTP credentials
- [ ] S3 bucket with proper permissions
- [ ] Environment variables properly secured
- [ ] System admin account with strong password
- [ ] Regular security updates applied

## Performance Optimization

1. **Database**: Use appropriate PostgreSQL configuration
2. **Redis**: Configure memory limits and eviction policies
3. **Web Server**: Adjust worker processes based on server capacity
4. **Assets**: Use CDN for static assets in production
5. **Monitoring**: Set up application performance monitoring

## Support

- **Decidim Documentation**: https://docs.decidim.org
- **Coolify Documentation**: https://coolify.io/docs
- **Community Support**: Decidim GitHub discussions

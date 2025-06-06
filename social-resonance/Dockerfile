# Base stage with common dependencies
FROM ruby:3.1 as base

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
      curl \
      wget \
      gnupg \
      lsb-release \
      postgresql-client \
      nodejs \
      npm \
      git \
      build-essential \
      libpq-dev \
      imagemagick \
      libvips42 && \
    rm -rf /var/lib/apt/lists/*

# Install latest Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs

# Set work directory for the entire workspace
WORKDIR /workspace

# Copy the entire repository structure
COPY . .

# Change to the social-resonance app directory
WORKDIR /workspace/social-resonance

# Install dependencies
RUN gem install bundler:2.4.22

# Development stage
FROM base as development

ENV RAILS_ENV=development
ENV NODE_ENV=development

# Install all dependencies (including development and test)
RUN bundle config set --local deployment 'false'
RUN bundle install --jobs 4 --retry 3

# Install Node.js dependencies (including dev dependencies)
RUN npm install

# Create necessary directories
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log public/uploads storage

# Set correct permissions
RUN chmod +x bin/*

# Expose port
EXPOSE 3000

# Simple entrypoint for development
RUN echo '#!/bin/bash\nset -e\ncd /workspace/social-resonance\nexec "$@"' > /usr/local/bin/dev-entrypoint.sh && \
    chmod +x /usr/local/bin/dev-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dev-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

# Production stage
FROM base as production

ENV RAILS_ENV=production
ENV NODE_ENV=production

# Install production dependencies only
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'
RUN bundle install --jobs 4 --retry 3

# Install Node.js dependencies (production only)
RUN npm ci --only=production

# Create necessary directories
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log public/uploads storage

# Set correct permissions
RUN chmod +x bin/*

# Precompile assets
RUN bundle exec rails assets:precompile

# Add health check script
RUN echo '#!/bin/bash\ncurl -f http://localhost:3000/health || exit 1' > /usr/local/bin/health-check && \
    chmod +x /usr/local/bin/health-check

# Expose port
EXPOSE 3000

# Add production entrypoint script
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Change to the app directory\n\
cd /workspace/social-resonance\n\
\n\
# Wait for database to be ready\n\
echo "Waiting for database..."\n\
until pg_isready -h ${DATABASE_HOST:-postgres} -p ${DATABASE_PORT:-5432} -U ${DATABASE_USERNAME:-postgres}; do\n\
  echo "Database is unavailable - sleeping"\n\
  sleep 1\n\
done\n\
echo "Database is up!"\n\
\n\
# Run database migrations\n\
echo "Running database migrations..."\n\
bundle exec rails db:migrate\n\
\n\
# Start the server\n\
echo "Starting application..."\n\
exec "$@"' > /usr/local/bin/prod-entrypoint.sh && \
    chmod +x /usr/local/bin/prod-entrypoint.sh

# Use the production entrypoint
ENTRYPOINT ["/usr/local/bin/prod-entrypoint.sh"]

# Default command
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

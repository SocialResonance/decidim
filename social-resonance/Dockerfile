FROM decidim/decidim:0.31.0.dev

# Set production environment
ENV RAILS_ENV=production
ENV NODE_ENV=production

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y \
      curl \
      wget \
      gnupg \
      lsb-release \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Set work directory for the entire workspace
WORKDIR /workspace

# Copy the entire repository structure
COPY . .

# Change to the social-resonance app directory
WORKDIR /workspace/social-resonance

# Install dependencies
RUN gem install bundler:2.4.22
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'development test'
RUN bundle install --jobs 4 --retry 3

# Install Node.js dependencies
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

# Add entrypoint script
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
exec "$@"' > /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

# Use the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

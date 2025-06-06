FROM ruby:3.3

ENV DEBIAN_FRONTEND noninteractive
ENV NODE_MAJOR=18

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    graphviz \
    imagemagick \
    libicu-dev \
    libpq-dev \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install node
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update -qq && apt-get install -y \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create workdir
RUN mkdir /decidim
WORKDIR /decidim

# Installs bundler dependencies
ENV \
  BUNDLE_BIN=/usr/local/bundle/bin \
  BUNDLE_JOBS=10 \
  BUNDLE_PATH=/usr/local/bundle \
  BUNDLE_RETRY=3 \
  GEM_HOME=/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"

# Copy the entire decidim monorepo
ADD . /decidim/

# Set working directory to social-resonance
WORKDIR /decidim/social-resonance

# Install bundler and bundle dependencies
RUN gem install bundler:2.4.20
RUN bundle install

# Compile assets
RUN npm i
RUN npm i -g yarn
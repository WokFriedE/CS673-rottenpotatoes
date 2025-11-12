# Use a Ruby base image compatible with Rails 4.2 and present OS repos
# Ruby 2.6 keeps the older BigDecimal API (e.g. BigDecimal.new) that Rails 4.2 expects
FROM ruby:2.6-slim-bullseye

# Use a sensible default environment
ENV RAILS_ENV=development

WORKDIR /app

# Install OS-level dependencies required to build gems and run Rails
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    sqlite3 \
    nodejs \
    npm \
    ca-certificates \
    git \
  && rm -rf /var/lib/apt/lists/*

# Install bundler matching the project (Gemfile.lock -> BUNDLED WITH)
RUN gem install bundler -v '1.17.3'

# Cache and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle _1.17.3_ install --jobs 4 --retry 5 --without production

# Copy the application
COPY . .

# Add a simple entrypoint to fix PID issues and then run the given CMD
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]

# Expose default Rails port
EXPOSE 3000

# Start Rails server binding to 0.0.0.0 so it's reachable from the host
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

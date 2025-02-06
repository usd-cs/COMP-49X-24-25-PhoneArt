# Use Swift official image
FROM swift:5.9

# Set working directory
WORKDIR /app

# Install required dependencies
RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Create build directory with proper permissions
RUN mkdir -p .build && chown -R root:root .build && chmod -R 777 .build

# Copy package manifest first (for better caching)
COPY ./Package.swift ./

# Copy entire project
COPY . .

# Ensure permissions are set correctly
RUN chown -R root:root /app && chmod -R 777 /app

# Build only (removing test since we're running in Linux)
CMD ["swift", "build"]
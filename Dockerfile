# Use a Flutter base image to build the app
FROM ghcr.io/cirruslabs/flutter:3.27.3 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy all project files into the container
COPY . .

# Install dependencies and build Flutter Web
RUN flutter config --no-analytics \
    && flutter doctor \
    && flutter pub get \
    && flutter build web

# Inject environment variables at build time
ARG API_BASE_URL
ARG GOOGLE_CLIENT_ID

# Build Flutter Web with --dart-define
RUN flutter clean && flutter pub get && flutter build web \
  --dart-define=API_BASE_URL=${API_BASE_URL} \
  --dart-define=GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}

# Use Nginx as the base image
FROM nginx:alpine

# Remove default Nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the Flutter Web build output to the Nginx web directory
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80 to serve the app
EXPOSE 80

# Start Nginx when the container runs
CMD ["nginx", "-g", "daemon off;"]

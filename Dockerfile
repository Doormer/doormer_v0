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

# The AdSense publisher ID (ca-pub-…), empty until the account exists.
ARG ADSENSE_CLIENT_ID=""

# Remove default Nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the Flutter Web build output to the Nginx web directory
COPY --from=build /app/build/web /usr/share/nginx/html

# With an AdSense publisher ID, the landing page carries Google's
# site-verification tag and /ads.txt names Doormer's account.
RUN if [ -n "$ADSENSE_CLIENT_ID" ]; then \
      echo "$ADSENSE_CLIENT_ID" | grep -Eq '^ca-pub-[0-9]{16}$' \
        || { echo "ADSENSE_CLIENT_ID must look like ca-pub-0000000000000000" >&2; exit 1; }; \
      sed -i "s|<!-- google-adsense-account -->|<meta name=\"google-adsense-account\" content=\"$ADSENSE_CLIENT_ID\">|" \
        /usr/share/nginx/html/site/pages/home.html; \
      echo "google.com, ${ADSENSE_CLIENT_ID#ca-}, DIRECT, f08c47fec0942fa0" > /usr/share/nginx/html/ads.txt; \
    fi

# Expose port 80 to serve the app
EXPOSE 80

# Start Nginx when the container runs
CMD ["nginx", "-g", "daemon off;"]

# Use a Flutter base image to build the app
FROM ghcr.io/cirruslabs/flutter:3.27.3 AS build

# Set the working directory inside the container
WORKDIR /app

# Copy all project files into the container
COPY . .

# Install dependencies and build Flutter Web
RUN flutter pub get && flutter build web

# Use Nginx as the base image
FROM nginx:alpine

# Copy the Flutter Web build output to the Nginx web directory
COPY build/web /usr/share/nginx/html

# Expose port 80 to serve the app
EXPOSE 80

# Start Nginx when the container runs
CMD ["nginx", "-g", "daemon off;"]

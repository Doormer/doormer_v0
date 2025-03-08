# Use Nginx as the base image
FROM nginx:alpine

# Copy the Flutter Web build output to the Nginx web directory
COPY build/web /usr/share/nginx/html

# Expose port 80 to serve the app
EXPOSE 80

# Start Nginx when the container runs
CMD ["nginx", "-g", "daemon off;"]

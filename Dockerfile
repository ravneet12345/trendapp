# Use lightweight Nginx to host static files
FROM nginx:stable-alpine

# Remove default site, copy compiled app
RUN rm -rf /usr/share/nginx/html/*
COPY dist/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

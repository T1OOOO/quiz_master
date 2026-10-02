ARG NGINX_IMAGE
FROM ${NGINX_IMAGE}
COPY nginx.conf /etc/nginx/nginx.conf
COPY api /app/api
COPY next /app/next
COPY web /usr/share/nginx/html
WORKDIR /app
USER 10001:10001
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

ARG NGINX_IMAGE=nginx@sha256:0985e772fb9f729e6fa0980da05fca5d9c468e870eed43071545afa9d2e27d94
FROM ${NGINX_IMAGE}
COPY nginx.conf /etc/nginx/nginx.conf
COPY --chmod=755 api /app/api
COPY next /app/next
COPY quizzes /app/quizzes
COPY web /usr/share/nginx/html
WORKDIR /app
USER 10001:10001
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

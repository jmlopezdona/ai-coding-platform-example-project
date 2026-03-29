FROM nginx:alpine
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY docker-entrypoint.sh /docker-entrypoint-custom.sh
RUN chmod +x /docker-entrypoint-custom.sh
COPY src/ /usr/share/nginx/html/
ENV BACKEND_URL=http://backend:8080
EXPOSE 3000
CMD ["/docker-entrypoint-custom.sh"]

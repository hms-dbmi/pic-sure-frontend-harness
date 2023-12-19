ARG IS_OPEN_ACCESS

FROM httpd:2.4.46-alpine as base

# Enable necessary proxy modules
RUN sed -i '/^#LoadModule proxy_module/s/^#//' ${HTTPD_PREFIX}/conf/httpd.conf
RUN sed -i  '/^#LoadModule proxy_http_module/s/^#//' ${HTTPD_PREFIX}/conf/httpd.conf
RUN sed -i '/^#LoadModule proxy_connect_module/s/^#//' ${HTTPD_PREFIX}/conf/httpd.conf

#### SSL ####
# enable ssl
RUN sed -i '/^#LoadModule ssl_module modules\/mod_ssl.so/s/^#//' ${HTTPD_PREFIX}/conf/httpd.conf
RUN sed -i '/^#LoadModule rewrite_module modules\/mod_rewrite.so/s/^#//' ${HTTPD_PREFIX}/conf/httpd.conf
RUN sed -i '/^#LoadModule socache_shmcb_module modules\/mod_socache_shmcb.so/s/^#//' ${HTTPD_PREFIX}/conf/httpd.conf
RUN sed -i 's/DirectoryIndex index.html/DirectoryIndex index_20210217.html/' ${HTTPD_PREFIX}/conf/httpd.conf
RUN mkdir -p /usr/local/apache2/logs/ssl_mutex

FROM base as open_access_stage-false
ARG PROJECT_SPECIFIC_UI_PATH

COPY ${PROJECT_SPECIFIC_UI_PATH}/src/main/resources/favicon.ico /usr/local/apache2/htdocs/

COPY ${PROJECT_SPECIFIC_UI_PATH}/horizontal-logo.png ${HTTPD_PREFIX}/htdocs/picsureui/static/logo.png
COPY ${PROJECT_SPECIFIC_UI_PATH}/stacked-logo.png ${HTTPD_PREFIX}/htdocs/images/logo.png
COPY ${PROJECT_SPECIFIC_UI_PATH}/login_dots.png ${HTTPD_PREFIX}/htdocs/images/login_dots.png

COPY repos/pic-sure-core-frontend/pic-sure-hpds-ui/target/webjars/META-INF/resources/webjars /usr/local/apache2/htdocs/picsureui/webjars

# Replace virtual host config file with ours
COPY httpd-vhosts.conf ${HTTPD_PREFIX}/conf/extra/httpd-vhosts.conf

# Enable virtual hosting config file
RUN sed -i '/^#Include conf.extra.httpd-vhosts.conf/s/^#//' ${HTTPD_PREFIX}/conf/httpd.conf

COPY repos/pic-sure-core-frontend/pic-sure-hpds-ui/src/main/webapp/picsureui /usr/local/apache2/htdocs/picsureui
COPY repos/pic-sure-core-frontend/pic-sure-hpds-ui/src/main/resources /usr/local/apache2/htdocs/picsureui/settings

COPY ${PROJECT_SPECIFIC_UI_PATH}/src/main/webapp/picsureui /usr/local/apache2/htdocs/picsureui/
COPY ${PROJECT_SPECIFIC_UI_PATH}/src/main/webapp/psamaui /usr/local/apache2/htdocs/picsureui/psamaui/

FROM open_access_stage-false as open_access_stage-true

ARG OPEN_ACCESS_SPECIFIC_UI_PATH
# The build will fail if the open-pic-sure-bdc-frontend folder isn't there.
COPY ${OPEN_ACCESS_SPECIFIC_UI_PATH}/src/main/picsureui/ /usr/local/apache2/htdocs/picsureui/

ARG IS_OPEN_ACCESS
FROM open_access_stage-${IS_OPEN_ACCESS} as final_stage
# The final stage is the stage is based on the value passed in for IS_OPEN_ACCESS (true or false)
# The final stage is the stage that will be used to build the image. By this time it already has the
ENV IS_OPEN_ACCESS=${IS_OPEN_ACCESS}
RUN echo "IS_OPEN_ACCESS: ${IS_OPEN_ACCESS}"
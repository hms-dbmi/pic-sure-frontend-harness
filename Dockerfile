FROM httpd:2.4.46-alpine

ARG PROJECT_SPECIFIC_UI_PATH

RUN echo ${PROJECT_SPECIFIC_UI_PATH} 

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

COPY ${PROJECT_SPECIFIC_UI_PATH}/src/main/resources/favicon.ico /usr/local/apache2/htdocs/

COPY ${PROJECT_SPECIFIC_UI_PATH}/horizontal-logo.png ${HTTPD_PREFIX}/htdocs/picsureui/static/logo.png
COPY ${PROJECT_SPECIFIC_UI_PATH}/stacked-logo.png ${HTTPD_PREFIX}/htdocs/images/logo.png

COPY repos/pic-sure-hpds-ui/pic-sure-hpds-ui/target/webjars/META-INF/resources/webjars /usr/local/apache2/htdocs/picsureui/webjars

# Replace virtual host config file with ours
COPY httpd-vhosts.conf ${HTTPD_PREFIX}/conf/extra/httpd-vhosts.conf

# Enable virtual hosting config file
RUN sed -i '/^#Include conf.extra.httpd-vhosts.conf/s/^#//' ${HTTPD_PREFIX}/conf/httpd.conf

COPY repos/pic-sure-hpds-ui/pic-sure-hpds-ui/src/main/webapp/picsureui /usr/local/apache2/htdocs/picsureui
COPY repos/pic-sure-hpds-ui/pic-sure-hpds-ui/src/main/resources /usr/local/apache2/htdocs/picsureui/settings

COPY ${PROJECT_SPECIFIC_UI_PATH}/src/main/webapp/picsureui /usr/local/apache2/htdocs/picsureui/
COPY ${PROJECT_SPECIFIC_UI_PATH}/src/main/webapp/psamaui /usr/local/apache2/htdocs/picsureui/psamaui/

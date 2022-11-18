FROM tomcat:9-jre8

ENV WEB_APP_DIR='/usr/local/tomcat/webapps' \
    GS_SERVER_VERSION="2.15.2" \
    APP_RUN="/var/appdata/run" \
    APP_FILES="/var/appdata/files" \
    TOMCAT_HOME="/usr/local/tomcat" \
    GEOSERVER_CONTEXT_ROOT="geoserver" \
    GEOSERVER_WAR_FILE="geoserver.war" \
    GEOSERVER_7z_FILE="geoserver.7z" \
    GEOSERVER_DATA_DIR="/opt/geoserver/data_dir" \
    TMP_FILE="/tmp/default.xml" 

# in case we want ot use an image from internet, instead of the "build_src/internet-dl/" folder
# ENV WAR_URL="http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_SERVER_VERSION}/geoserver-${GS_SERVER_VERSION}-war.zip"

RUN mkdir -p ${APP_RUN} && \
    mkdir -p ${APP_FILES}

ADD build_src ${APP_FILES}
ADD build_src/scripts ${APP_RUN}
RUN chmod 750 ${APP_RUN}/*.sh

# Obfuscate the version number of Tomcat
RUN mkdir -p $CATALINA_HOME/lib/org/apache/catalina/util && \ 
    echo "server.info=Apache Tomcat" > $CATALINA_HOME/lib/org/apache/catalina/util/ServerInfo.properties

## As the war file is over 100 MiB, github will not accept the upload.
# Instead 7zip is used, with max compression, to facilitate offering the file.

COPY build_src/internet-dl/geoserver-*.7z ${WEB_APP_DIR}/${GEOSERVER_7z_FILE}
RUN apt update && apt install -y p7zip-full gettext-base
WORKDIR ${WEB_APP_DIR}
RUN 7z x ${WEB_APP_DIR}/${GEOSERVER_7z_FILE} -y && \
    rm -rf ${WEB_APP_DIR}/${GEOSERVER_7z_FILE}

# Data dir init 
RUN mkdir -p ${GEOSERVER_DATA_DIR}

# Copy the full data_dir into the environment
COPY data_dir ${GEOSERVER_DATA_DIR}

# Add IFK context.xml to conf/context.xml. This addition is required in order to correctly include the local-postgresql name
#  as configuration for GeoServer.
COPY build_src/config/context.xml ${TOMCAT_HOME}/conf/context.xml

# Log4j logging
COPY build_src/config/logs/* ${GEOSERVER_DATA_DIR}/

# Enable CORS 
COPY build_src/config/web.xml ${TOMCAT_HOME}/conf/

# Application defined template xml files. Variables inside need to be matched to ENV variables via 'envsubst'
COPY build_src/config/server.template.xml ${APP_FILES}/server.template.xml

# Clean webapp dir and remove unused apps
RUN rm -rf ${WEB_APP_DIR}/ROOT && \
    rm -rf ${WEB_APP_DIR}/docs && \
    rm -rf ${WEB_APP_DIR}/examples && \
    rm -rf ${WEB_APP_DIR}/host-manager && \
    rm -rf ${WEB_APP_DIR}/manager

# Clean apt-get log
RUN apt-get clean && \
    rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp

WORKDIR /usr/local/tomcat

CMD ["/var/appdata/run/entrypoint.sh"]
# CMD ["tail", "-f", "/dev/null"]
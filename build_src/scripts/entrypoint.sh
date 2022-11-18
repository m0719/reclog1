#!/bin/bash
set -e

source /root/.bashrc

export GEOSERVER_OPTS="-Djava.awt.headless=true -server -Xms${INITIAL_MEMORY} -Xmx${MAXIMUM_MEMORY} -Xrs -XX:PerfDataSamplingInterval=500 \
       -Dorg.geotools.referencing.forceXY=true -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParallelGC -XX:NewRatio=2 \
       -XX:+CMSClassUnloadingEnabled -Dfile.encoding=UTF8 -Duser.timezone=GMT -Djavax.servlet.request.encoding=UTF-8 \
       -Djavax.servlet.response.encoding=UTF-8 -Duser.timezone=GMT -Dorg.geotools.shapefile.datetime=true \
       -Dorg.geotools.shapefile.datetime=true -Ds3.properties.location=/opt/geoserver/data_dir/s3.properties \
       -Xbootclasspath/a:${CATALINA_HOME}/webapps/geoserver/WEB-INF/lib/marlin.jar \
       -Xbootclasspath/p:${CATALINA_HOME}/webapps/geoserver/WEB-INF/lib/marlin-sun-java2d.jar \
       -Dsun.java2d.renderer=org.marlin.pisces.PiscesRenderingEngine"

## Preparare the JVM command line arguments
export JAVA_OPTS="${JAVA_OPTS} ${GEOSERVER_OPTS}"

## Update geoserver password with ENV variable geoserver_adminpw.
# This var can either be manually set or come from Kubernetes Secret
/var/appdata/run/update_password.sh

# Delete the basic auth filter. This conflicts with the basic auth used by the viewer. 
if [ -d "/opt/geoserver/data_dir/security/filter/basic/" ]; then
    rm -rf /opt/geoserver/data_dir/security/filter/basic/
fi 

## Replace found ${variables} by ENV variables via 'envsubst'
TOMCAT_HOME="/usr/local/tomcat"
APP_FILES="/var/appdata/files"

envsubst < ${APP_FILES}/server.template.xml > ${TOMCAT_HOME}/conf/server.xml

exec /usr/local/tomcat/bin/catalina.sh run

# GeoServer

Geoserver contructed from the ground up, based on the zip file found on the official geoserver download homepage:
http://geoserver.org/download/

## Pre-Requirements

For succesfully running this Repo you need to have at least docker (locally) installed. The image has been constructed mainly for usage within Kubernetes, but
local test runs are also possible.

## Building the image
To build the image locally, build it via the following command: `docker build --no-cache -t <imagename:imagetag> .`

# GeoServer configuration / docker image

To succesfully run the image locally or dedicated, the following info has to be supplied:

## Mandatory
- -Xms${INITIAL_MEMORY}
  - Initial memory used to start the container with. This ENV isn't linked and has to be set manually.
  - Not setting it will result in the application not starting!
- -Xmx${MAXIMUM_MEMORY}
  - Maximum memory used to start the container with. This ENV isn't linked and has to be set manually. 
  - Not setting it will result in the application not starting!
- ${geoserver_adminpw}
  - Admin password to be set for accessing Geoserver. 
  - Please note the user is always "admin". 
  - The password will be stored encrypted inside the "users.xml" file, found in the ${GEOSERVER_DATA_DIR} directory.

## Optional 
(for use mainly within the server.xml file in /usr/local/tomcat/conf/server.xml)
- ${ResContainer}
  - For exmaple: "Container"
- ${ResType}
  - For exmaple: "javax.sql.DataSource"
- ${ResDriverClass}
  - For exmaple: "org.postgresql.Driver
- ${ResUrl}
  - For exmaple: "postgis-service"
- ${ResPort}
  - For exmaple: "5432"
- ${ResUsername}
  - For exmaple: "localuser"
- ${ResPassword}
  - For exmaple: "localpassword"
- ${ResMaxTotal}
  - For exmaple: "8"
- ${ResMinIdle}
  - For exmaple: "0"
- ${ResMaxIdle}
  - For exmaple: "8"
- ${ResValQry}
  - For exmaple: "SELECT 1"

# Launching

## Run locally
The following command(s) can be used to run the image locally. The "$1" needs to be replaced with the name of the image that was build.
The geoserver_adminpw in this example is plaintext. This ENV can also be linked to a Docker / Kubernetes Secret.
```
docker run -ti  \
    --rm \
    --entrypoint=/bin/bash \
    -p 8080:8080 \
    -e docker_app_name="geoserver" \
    -e INITIAL_MEMORY="2G" \
    -e MAXIMUM_MEMORY="4G" \
    -e geoserver_adminpw=\"blabla\" \
    -e ResContainer="Container" \
    -e ResType="javax.sql.DataSource" \
    -e ResDriverClass="org.postgresql.Driver" \
    -e ResUrl="postgis-service" \
    -e ResPort="5432" \
    -e ResUsername="localuser" \
    -e ResPassword="localpassword" \
    -e ResMaxTotal="8" \
    -e ResMinIdle="0" \
    -e ResMaxIdle="8" \
    -e ResValQry="SELECT 1" \
    $1
```

## Run dedicated

```
docker run -d  \
    --rm \
    --name="geoserver-local" \
    --entrypoint=/bin/bash \
    -p 8080:8080 \
    -e docker_app_name="geoserver" \
    -e INITIAL_MEMORY="2G" \
    -e MAXIMUM_MEMORY="4G" \
    -e geoserver_adminpw=\"blabla\" \
    -e ResContainer="Container" \
    -e ResType="javax.sql.DataSource" \
    -e ResDriverClass="org.postgresql.Driver" \
    -e ResUrl="postgis-service" \
    -e ResPort="5432" \
    -e ResUsername="localuser" \
    -e ResPassword="localpassword" \
    -e ResMaxTotal="8" \
    -e ResMinIdle="0" \
    -e ResMaxIdle="8" \
    -e ResValQry="SELECT 1" \
    $1
```

# Extra info

## Use of variables in files
In order to copy over the value from ${variables} into a file, the command `envsubst` is used within this repo. 
This command comes from the `gettext-base` package and is installed via `apt install`.

Usage is `envsubst < inputfile > outputfile`.
For example, taken from the `entrypoint.sh` script (stored in build_src/scripts/):

```
## Replace found ${variables} by ENV variables via 'envsubst'
# 
TOMCAT_HOME="/usr/local/tomcat"
APP_FILES="/var/appdata/files"

envsubst < ${APP_FILES}/server.template.xml > ${TOMCAT_HOME}/conf/server.xml

##
```
The reason for using two files, instead of just using the same file as input and output, is when later the variables have to be found, which can be done in a search of the template.
Instead of manually searching for unmatched ${variables} the use of grep can also be used. 

Grep can also be used. Just point the <directory> towards your search location and grep will recursively search inside all files for missing / unset variables: `cd <directory> && grep -Ri '\$\{'`
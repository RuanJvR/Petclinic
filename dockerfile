# Set base image
FROM maven:3.6.3-jdk-8 AS build-env

# Declare build arguments
ARG VERSIONNUMBER
ARG SERVERNAME
ARG DATABASENAME
ARG USERNAME
ARG USERPASSWORD

# Ensure versionnumber has a value
RUN [ -z "$VERSIONNUMBER" ] && echo "VERSIONNUMBER is required" && exit 1 || true

# Set working directory
WORKDIR /app

# Copy in POM file
COPY pom.xml ./

# Resolve dependencies
RUN mvn dependency:resolve

# Copy in application source
COPY /src ./src/

# Build .war
RUN mvn clean package -DskipTests -Dproject.versionNumber=$VERSIONNUMBER -DdatabaseServerName=$SERVERNAME -DdatabaseName=$DATABASENAME -DdatabaseUserName=$USERNAME -DdatabaseUserPassword=$USERPASSWORD

# Use tomcat base image
FROM tomcat:8.0.51-jre8-alpine

# Declare argument
ARG VERSIONNUMBER

# Remove default items
RUN rm -rf /usr/local/tomcat/webapps/*

# Expose the port
EXPOSE 8080

# Copy in the .war file to the root for tomcat
COPY --from=build-env /app/target/petclinic.web.$VERSIONNUMBER.war /usr/local/tomcat/webapps/ROOT.war

# Install xmlstarlet and zip
RUN apk add --update xmlstarlet
RUN apk add --update zip

# Copy petclinic
COPY petclinic.sh ./

# Run tomcat
#CMD ["catalina.sh","run"]
CMD ["bash", "petclinic.sh"]


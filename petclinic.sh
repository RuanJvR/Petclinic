#!/bin/sh

# Check if any of the environment variables are set
if [ ! -z "$URL" ]  || [ ! -z "$USERNAME" ] || [ ! -z "$USERPASSWORD" ]; then
    # Create tmp folder
    mkdir /tmp/ROOT   
    
    # Expand .war into temp
    echo "Unpacking .war ..."
    unzip /usr/local/tomcat/webapps/ROOT.war -d /tmp/ROOT

    # Check to see if environment variable for url is set
    if [ ! -z "$URL" ]; then
        echo "Updating URL with environment variable ..."
        xmlstarlet edit --inplace --update "/*[local-name()='beans'][namespace-uri()='http://www.springframework.org/schema/beans']/*[local-name()='bean'][namespace-uri()='http://www.springframework.org/schema/beans']/*[local-name()='property'][namespace-uri()='http://www.springframework.org/schema/beans'][@name='url']/@value" --value "$URL" /tmp/ROOT/WEB-INF/classes/spring/datasource-config.xml 
    fi

    # Check to see if username is set
    if [ ! -z "$USERNAME" ]; then
        echo "Updating USERNAME with environment variable ..."
        xmlstarlet edit --inplace --update "/*[local-name()='beans'][namespace-uri()='http://www.springframework.org/schema/beans']/*[local-name()='bean'][namespace-uri()='http://www.springframework.org/schema/beans']/*[local-name()='property'][namespace-uri()='http://www.springframework.org/schema/beans'][@name='username']/@value" --value "$USERNAME" /tmp/ROOT/WEB-INF/classes/spring/datasource-config.xml
    fi

    # Check to see if password is set
    if [ ! -z "$USERPASSWORD" ]; then
        echo "Updating USERPASSWORD with environment variable..."
        xmlstarlet edit --inplace --update "/*[local-name()='beans'][namespace-uri()='http://www.springframework.org/schema/beans']/*[local-name()='bean'][namespace-uri()='http://www.springframework.org/schema/beans']/*[local-name()='property'][namespace-uri()='http://www.springframework.org/schema/beans'][@name='password']/@value" --value "$USERPASSWORD" /tmp/ROOT/WEB-INF/classes/spring/datasource-config.xml
    fi

    # Remove existing .war
    rm /usr/local/tomcat/webapps/ROOT.war

    # Zip new .war
    echo "Repacking .war"
    cd /tmp/ROOT
    zip -r ROOT.war .
    cp /tmp/ROOT/ROOT.war /usr/local/tomcat/webapps/ROOT.war

    # Remove temporary folder
    cd /usr/local/tomcat
    rm -rf /tmp/ROOT
fi

# Start Tomcat
catalina.sh run
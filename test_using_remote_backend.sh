#!/bin/bash

if [ ! -d repos ]
then
	mkdir repos
	echo
	echo "The repos directory has been created, please clone any desired project specific override repo."
	echo "The pic-sure-hpds-ui repo has alread been cloned there for you, please make sure to checkout the"
	echo "correct branch or git commit"
	echo
	exit -1
fi

if [ -z "$PROJECT_SPECIFIC_UI_PATH" ]
then
    echo 
    echo "\$PROJECT_SPECIFIC_UI_PATH environment variable must be set to the path to the maven project for the ui overrides."
    echo "This path should be relative to the repos directory where you should have cloned the project specific overrides repo."
    echo 
    exit -1
fi


if [ -z "$BACKEND_HOST" ]
then
    echo 
    echo "\$BACKEND_HOST environment variable must be set to the domain name of the environment you are using as a backend."
    echo "The BACKEND_HOST should belong to the project specific override repo that you wish to develop for."
    echo
    echo "Additionally, you should add an /etc/hosts entry for this domain to point at 127.0.0.1 or whatever your"
    echo "Docker host IP is"
    echo 
    exit -1
fi

if [ -z "$BACKEND_IP" ]
then
	echo 
	echo "\$BACKEND_IP not set, setting using nslookup, remember this does not honor your /etc/hosts file"
	echo "Set \$BACKEND_IP to a different IP if you don't want to hit the public DNS target for $BACKEND_HOST"
    BACKEND_IP=$(nslookup $BACKEND_HOST |  grep -A2 $BACKEND_HOST | tail -1 | cut -d ' ' -f 2)
    echo 
fi

if [ -z "$ADDITIONAL_VOLUMES" ]
then
	echo 
	echo "\$ADDITIONAL_VOLUMES not set, no additional volume mountings will be configured"
	echo
	echo "If your specific environment has files that the UI normally gets out of band, this is where you can add them."
	echo "It is usually best to place them in the repos directory so they don't end up getting checked into git."
	echo
	echo "Set \$ADDITIONAL_VOLUMES to a list of space separated -v arguments for the docker run command."
	echo
	echo "Examples : "
	echo "   export ADDITIONAL_VOLUMES=\"-v $(pwd)/repos/studies-data.json:/usr/local/apache2/htdocs/picsureui/studyAccess/studies-data.json \""
    echo "   export ADDITIONAL_VOLUMES=\"-v $(pwd)/repos/path_a:/usr/local/apache2/htdocs/path_a -v $(pwd)/path_b:/usr/local/apache2/htdocs/path_b \""
    echo 
    echo "Things tend to behave best if you leave a space at the end of the list of volumes as shown above."
    echo
fi

if [ ! -f cert/localhost.ca.pem ] 
then
	echo 
	echo "localhost.ca Certificate Authority not created, creating a new one"
	echo 
	./create_localhost_ca.sh
	echo 
	exit -1
fi

CERT_HOST=$(openssl x509 -in cert/server.crt -text -noout | grep DNS | cut -d ':' -f 2) 
if { [ -z $CERT_HOST ] || [ $CERT_HOST != $BACKEND_HOST ]; }; then
	echo 
	echo "Certificate not configured for $BACKEND_HOST, reconfiguring certificate"
	echo 
	./configure_local_ssl.sh $BACKEND_HOST
fi

echo $PROJECT_SPECIFIC_UI_PATH
docker build --build-arg=PROJECT_SPECIFIC_UI_PATH=$PROJECT_SPECIFIC_UI_PATH -t picsureui .
docker stop httpd || true
docker rm httpd || true
docker run --name=httpd  \
  -v $(pwd)/httpd-docker-logs/:/usr/local/apache2/logs/ \
  -v $(pwd)/httpd-vhosts.conf:/usr/local/apache2/conf/extra/httpd-vhosts.conf \
  -v $(pwd)/cert/server.crt:/usr/local/apache2/cert/server.crt \
  -v $(pwd)/cert/server.chain:/usr/local/apache2/cert/server.chain \
  -v $(pwd)/cert/server.key:/usr/local/apache2/cert/server.key \
  -v $(pwd)/httpd-docker-logs/ssl_mutex:/usr/local/apache2/logs/ssl_mutex \
  $ADDITIONAL_VOLUMES \
  -e BACKEND_HOST=$BACKEND_HOST \
  -e BACKEND_IP=$BACKEND_IP \
  --add-host $BACKEND_HOST:$BACKEND_IP \
  -p 80:80 \
  -p 443:443 \
  --dns 8.8.8.8 \
  -d picsureui

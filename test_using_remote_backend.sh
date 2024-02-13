#!/bin/bash

export BACKEND_HOST=
export BACKEND_IP=
export PROJECT_SPECIFIC_UI_PATH=repos/PIC-SURE-Frontend

if [ ! -d repos ] 
then
	mkdir repos
  cd repos
  git clone https://github.com/hms-dbmi/PIC-SURE-Frontend
	echo
	echo "The repos directory has been created, please clone any desired project specific override repo in the repos directory."
	echo "The PIC-SURE-Frontend repo has alread been cloned there for you, please make sure to checkout the"
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


cp httpd-vhosts.conf $PROJECT_SPECIFIC_UI_PATH/
cp -r cert $PROJECT_SPECIFIC_UI_PATH/cert

echo "Stopping and removing any existing httpd container..."
echo $PROJECT_SPECIFIC_UI_PATH
cd $PROJECT_SPECIFIC_UI_PATH
docker stop httpd || true
docker rm httpd || true
docker build -t picsureui .
docker run --name=httpd  \
  -v $(pwd)/httpd-docker-logs/:/usr/local/apache2/logs/ \
  -v $(pwd)/httpd-vhosts.conf:/usr/local/apache2/conf/extra/httpd-vhosts.conf \
  -v $(pwd)/cert/server.crt:/usr/local/apache2/cert/server.crt \
  -v $(pwd)/cert/server.chain:/usr/local/apache2/cert/server.chain \
  -v $(pwd)/cert/server.key:/usr/local/apache2/cert/server.key \
  -v $(pwd)/httpd-docker-logs/ssl_mutex:/usr/local/apache2/logs/ssl_mutex \
  -e BACKEND_HOST=$BACKEND_HOST \
  -e BACKEND_IP=$BACKEND_IP \
  --add-host $BACKEND_HOST:$BACKEND_IP \
  -p 80:80 \
  -p 443:443 \
  --dns 8.8.8.8 \
  -d picsureui

echo
echo "Remember to set $BACKEND_HOST to point at your docker host ip in /etc/hosts."
echo
echo "You should now be able to point your browser at $BACKEND_HOST and load the repos in the "
echo "repos folder into your IDE to perform development."
echo
echo "Any time you update a file in your IDE just re-run this script to update the test"
echo "environment and refresh your page."
echo


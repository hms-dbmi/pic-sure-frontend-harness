#!/bin/bash

function print_env_options() {
  echo "Usage: $0 [option]"
  echo "Options:"
  echo "-nh, --nhanes-dev-local"
  echo "-bdc-a, --biodatacatalyst-integration"
  echo "-bdc-dev, --biodatacatalyst-integration-dev"
  echo "-bdc-a-open, --biodatacatalyst-integration-open"
  exit 1
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in 
    -nh|--nhanes-dev)
      OPTION="NHANES-DEV"
      shift
      ;;
    -nh-local|--nhanes-dev-local)
      OPTION="NHANES-DEV-LOCAL"
      shift
      ;;
    -bdc-a|--biodatacatalyst-integration-a)
      OPTION="BDC-INT-A"
      shift
      ;;
    -bdc-dev|--biodatacatalyst-integration-dev)
      OPTION="BDC-INT-DEV"
      shift
      ;;
    -bdc-a-open|--biodatacatalyst-integration-open)
      OPTION="BDC-INT-A-OPEN"
      shift
      ;;
    -h|--help)
      print_env_options
      ;;
    *)
    echo "Error: Unknown option: $1"
  esac
done

# Set the current directory to the directory of this script
cd "$(dirname "$0")"

# Check if option was provided
if [ -z "$OPTION" ]; then
  echo "Error: No option provided"
  print_env_options
else
  case $OPTION in
    "NHANES-DEV")
      export BACKEND_HOST=nhanes-dev.hms.harvard.edu
      export BACKEND_IP=54.152.68.49
      export PROJECT_SPECIFIC_UI_PATH=repos/baseline-pic-sure/ui
      export ADDITIONAL_VOLUMES=" -v $(pwd)/repos/settings.json:/usr/local/apache2/htdocs/picsureui/settings/settings.json "
      export IS_OPEN_ACCESS=false
      ;;
    "NHANES-DEV-LOCAL")
      export BACKEND_HOST=picsure.local
      export BACKEND_IP=192.168.1.63
      export PROJECT_SPECIFIC_UI_PATH=repos/baseline-pic-sure/ui
      export ADDITIONAL_VOLUMES=" -v $(pwd)/repos/settings.json:/usr/local/apache2/htdocs/picsureui/settings/settings.json "
      export IS_OPEN_ACCESS=false
      ;;
    "BDC-INT-DEV")
      export BACKEND_HOST=biodatacatalyst.integration.hms.harvard.edu
      export BACKEND_IP=3.80.150.143
      export PROJECT_SPECIFIC_UI_PATH=repos/biodatacatalyst-pic-sure/biodatacatalyst-ui
      export ADDITIONAL_VOLUMES=" -v $(pwd)/repos/bdc_settings/variant-data.json:/usr/local/apache2/htdocs/picsureui/studyAccess/variant-data.json -v $(pwd)/repos/bdc_settings/studies-data.json:/usr/local/apache2/htdocs/picsureui/studyAccess/studies-data.json -v $(pwd)/repos/bdc_settings/bdc_settings.json:/usr/local/apache2/htdocs/picsureui/settings/settings.json " 
      export IS_OPEN_ACCESS=false
      ;;
    "BDC-INT-A")
      export BACKEND_HOST=biodatacatalyst.integration.hms.harvard.edu
      export BACKEND_IP=3.234.102.16
      export PROJECT_SPECIFIC_UI_PATH=repos/biodatacatalyst-pic-sure/biodatacatalyst-ui
      export ADDITIONAL_VOLUMES=" -v $(pwd)/repos/bdc_settings/variant-data.json:/usr/local/apache2/htdocs/picsureui/studyAccess/variant-data.json -v $(pwd)/repos/bdc_settings/studies-data.json:/usr/local/apache2/htdocs/picsureui/studyAccess/studies-data.json -v $(pwd)/repos/bdc_settings/bdc_settings.json:/usr/local/apache2/htdocs/picsureui/settings/settings.json -v $(pwd)/repos/bdc_settings/bannerConfig.json:/usr/local/apache2/htdocs/picsureui/settings/banner_config.json"
      export IS_OPEN_ACCESS=false
      ;;
    "BDC-INT-A-OPEN")
#          export BACKEND_HOST=biodatacatalyst.integration.hms.harvard.edu
#          export BACKEND_IP=3.234.102.16
          export BACKEND_HOST=predev.openpicsure.biodatacatalyst.nhlbi.nih.gov
          export BACKEND_IP=10.129.17.48
          export PROJECT_SPECIFIC_UI_PATH=repos/biodatacatalyst-pic-sure/biodatacatalyst-ui
          export OPEN_ACCESS_SPECIFIC_UI_PATH=repos/biodatacatalyst-pic-sure/repos/open-pic-sure-bdc-frontend/ui
          export ADDITIONAL_VOLUMES=" -v $(pwd)/repos/bdc_settings/variant-data.json:/usr/local/apache2/htdocs/picsureui/studyAccess/variant-data.json -v $(pwd)/repos/bdc_settings/studies-data.json:/usr/local/apache2/htdocs/picsureui/studyAccess/studies-data.json -v $(pwd)/repos/bdc_settings/bdc_settings.json:/usr/local/apache2/htdocs/picsureui/settings/settings.json "
          export IS_OPEN_ACCESS=true
      ;;
  esac

  if [ ! -d repos ]
  then
    mkdir repos
    cd repos
    git clone https://github.com/hms-dbmi/pic-sure-hpds-ui
    echo
    echo "The repos directory has been created, please clone any desired project specific override repo in the repos directory."
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

  if [ ! -d $PROJECT_SPECIFIC_UI_PATH/target ]
  then
    WORKING_DIR=$(pwd)
    cd $PROJECT_SPECIFIC_UI_PATH
    mvn clean install -DskipTests
    cd $WORKING_DIR
    unset $WORKING_DIR
  fi

  if [ ! -d repos/pic-sure-hpds-ui/pic-sure-hpds-ui/target ]
  then
    cd repos/pic-sure-hpds-ui
    mvn clean install -DskipTests
    cd ../../
  fi

  # input list of domains separated by commas
  DOMAINS=$BACKEND_HOST

  # convert commas to space
  DOMAINS_ARRAY=${DOMAINS//,/ }

  # convert array of domains to regex
  REGEX_DOMAINS=$(echo $DOMAINS_ARRAY | sed 's/ /\\|/g')



  echo $PROJECT_SPECIFIC_UI_PATH
  docker build --build-arg=PROJECT_SPECIFIC_UI_PATH=$PROJECT_SPECIFIC_UI_PATH \
    --build-arg=IS_OPEN_ACCESS=$IS_OPEN_ACCESS \
    --build-arg=OPEN_ACCESS_SPECIFIC_UI_PATH=$OPEN_ACCESS_SPECIFIC_UI_PATH \
    -t picsureui .
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
    -e REGEX_DOMAINS=$REGEX_DOMAINS \
    --add-host $BACKEND_HOST:$BACKEND_IP \
    -p 80:80 \
    -p 443:443 \
    --dns 8.8.8.8 \
    -d picsureui

echo
echo "Remember to set $BACKEND_HOST to point at your docker host ip in /etc/hosts."
  echo
  echo "Remember to set $BACKEND_HOST to point at your docker host ip in /etc/hosts."
  echo
  echo "You should now be able to point your browser at $BACKEND_HOST and load the repos in the "
  echo "repos folder into your IDE to perform development."
  echo
  echo "Any time you update a file in your IDE just re-run this script to update the test"
  echo "environment and refresh your page."
  echo
fi
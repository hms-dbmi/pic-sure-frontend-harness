#!/bin/bash

if [ $# -eq 0 ]
	then 
		echo
		echo "Please supply a domain name to generate a cert for as the only argument to this script."
		echo 
		echo "Example : ./configure_local_ssl.sh some.domain.that.hosts.picsure.com"
		echo
		exit -1
fi

NAME=$1 

openssl genrsa -out cert/server.key 2048
openssl req -new -key cert/server.key -out cert/$NAME.csr \
   -subj "/C=US/ST=MA/L=DEVELOPER_ONLY/O=DEVELOPER_ONLY/OU=DEVELOPER_ONLY/CN=$BACKEND_HOST/emailAddress=nobody@nowhere.com"
>cert/$NAME.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $NAME 
EOF

openssl x509 -req -in cert/$NAME.csr -CA cert/localhost.ca.pem -CAkey cert/localhost.ca.key -CAcreateserial \
   -out cert/server.crt -days 825 -sha256 -extfile cert/$NAME.ext 

cp cert/server.crt cert/server.chain
#!/bin/bash
mkdir -p  cert
openssl genrsa -out cert/localhost.ca.key 2048
openssl req -x509 -new -nodes -key cert/localhost.ca.key -sha256 -days 825 -out cert/localhost.ca.pem \
-subj "/C=US/ST=MA/L=DEVELOPER_ONLY/O=DEVELOPER_ONLY/OU=DEVELOPER_ONLY/CN=localhost.ca/emailAddress=nobody@nowhere.com"

echo
echo "The localhost.ca.pem must now be imported into your local certificate store and trusted."
echo
echo "On a mac you can do this by following these steps:"
echo "   - Open Keychain Access from the launcher"
echo "   - Delete any existing certificate entry named localhost.ca"
echo "   - Select Import Items from the File menu."
echo "   - Navigate to and select the cert/localhost.ca.pem file in the cert folder."
echo "   - Find and double-click localhost.ca in the list of certificates."
echo "   - Expand the Trust panel and where it says 'When using this certificate:' select Always Trust"
echo "   - Close out and restart any browsers you had open. Your browsers will now trust certs generated by your local CA."
echo


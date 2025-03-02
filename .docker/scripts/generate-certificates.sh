#!/bin/bash

# Based on this answer https://stackoverflow.com/a/53826340/766838

SERVER="${1:-localhost}"

# Subject
CORPORATION=GPWeinschutz
GROUP=Group
CITY=City
STATE=State
COUNTRY=BR

# Global variables
SCRIPT_DIR=$(dirname $(readlink -f $0))
CERT_DIR=$(realpath ${SCRIPT_DIR}/../nginx/certificates)
CA_DIR=${CERT_DIR}/ca
if [ ! -d ${CA_DIR} ]; then
    mkdir -p ${CA_DIR}
fi

CLIENT_DIR=${CERT_DIR}/client
if [ ! -d ${CLIENT_DIR} ]; then
    mkdir -p ${CLIENT_DIR}
fi

PRIVATE_KEY="${CA_DIR}/${CORPORATION}-key.pem"
CERT_AUTHORITY="${CA_DIR}/${CORPORATION}.pem"
CLIENT_PRIVATE_KEY="${CLIENT_DIR}/${SERVER}-key.pem"
CLIENT_SIGNING_REQUEST="${CLIENT_DIR}/${SERVER}.csr"
CLIENT_CERTIFICATE="${CLIENT_DIR}/${SERVER}.pem"

# Generate a random password
CERT_AUTH_PASS=`openssl rand -base64 32`
echo $CERT_AUTH_PASS > ${CERT_DIR}/cert_auth_password
CERT_AUTH_PASS=`cat ${CERT_DIR}/cert_auth_password`

# Create the certificate authority
if [ ! -f ${PRIVATE_KEY} ] || [ ! -f ${CERT_AUTHORITY} ]; then
    openssl \
        req \
        -subj "/CN=${SERVER}.ca/OU=${GROUP}/O=${CORPORATION}/L=${CITY}/ST=${STATE}/C=${COUNTRY}" \
        -new \
        -x509 \
        -passout pass:${CERT_AUTH_PASS} \
        -keyout ${PRIVATE_KEY} \
        -out ${CERT_AUTHORITY} \
        -days 36500
else
    echo "Certificate authority already exists. Skipping..."
fi

# Create client private key (used to decrypt the cert we get from the CA)
if [ ! -f ${CLIENT_PRIVATE_KEY} ]; then
    openssl genrsa -passout pass:${CERT_AUTH_PASS} -out ${CLIENT_PRIVATE_KEY}
else
    echo "Client private key already exists. Skipping..."
fi

# Create the CSR(Certitificate Signing Request)
if [ ! -f ${CLIENT_SIGNING_REQUEST} ]; then
    openssl \
        req \
        -new \
        -nodes \
        -subj "/CN=${SERVER}/OU=${GROUP}/O=${CORPORATION}/L=${CITY}/ST=${STATE}/C=${COUNTRY}" \
        -sha256 \
        -passin pass:${CERT_AUTH_PASS} \
        -extensions v3_req \
        -reqexts SAN \
        -key ${CLIENT_PRIVATE_KEY} \
        -out ${CLIENT_SIGNING_REQUEST} \
        -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:${SERVER}"))
else
    echo "Client certificate already exists. Skipping..."
fi

# Sign the certificate with the certificate authority
if [ ! -f ${CLIENT_CERTIFICATE} ]; then
    openssl \
        x509 \
        -req \
        -days 36500 \
        -passin pass:${CERT_AUTH_PASS} \
        -in ${CLIENT_SIGNING_REQUEST} \
        -CA ${CERT_AUTHORITY} \
        -CAkey ${PRIVATE_KEY} \
        -CAcreateserial \
        -out ${CLIENT_CERTIFICATE} \
        -extfile <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:${SERVER}")) \
        -extensions SAN
else
    echo "Client certificate already exists. Skipping..."
fi

#!/bin/bash
mkdir -p certs/pki
cd certs
wget -nc https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O cfssl
wget -nc https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O cfssljson
chmod +x cfssl*
if [ ! -f pki/ca.crt ]; then
   ./cfssl gencert -initca ../ca-csr.json | ./cfssljson -bare ca
   cp ca-key.pem pki/ca.key
   cp ca.pem pki/ca.crt
fi
cd ../
wget -nc https://github.com/coreos/etcd/releases/download/v3.3.10/etcd-v3.3.10-linux-amd64.tar.gz
if [ ! -f etcd ]; then
tar xf etcd-v3.3.10-linux-amd64.tar.gz
mv -n etcd-v3.3.10-linux-amd64 etcd
fi

#!/bin/bash

[ ! -f ca.crt -o ! -f ca.key ] && openssl req -newkey rsa:4096 -nodes -sha256 -keyout ca.key -x509 -days 3650 -out ca.crt -subj "/C=CN/L=London/O=Company Ltd/CN=nginx-docker"

for i in $(echo $1 |sed 's/,/ /g');do
 if [ ! -f "$i.crt" -o ! -f "$i.key" ]; then
    openssl req -newkey rsa:4096 -nodes -sha256 -keyout $i.key -out $i.csr -subj "/C=CN/L=London/O=Company Ltd/CN=$i"
    openssl x509 -req -days 3650 -in $i.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out $i.crt
 fi
    echo "$i|$i%backend_https=y,crt_key=$i.crt|$i.key"
done
echo

# ./x $(cat txt) | tr '\n' ';' | sed 's/;;/\n/' | tee domain.txt

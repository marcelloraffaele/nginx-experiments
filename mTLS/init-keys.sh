cd keys
echo "creating rootCA"
openssl genrsa -des3 -out rootCA.key 4096
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.crt
echo "creating server keys"
openssl genrsa -out server.key 2048
openssl req -new -sha256 -key server.key -subj "/C=IT/ST=IT/O=mytest.local, Inc./CN=server.local" -out server.csr
openssl x509 -req -in server.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out server.crt -days 500 -sha256
echo "creating client keys"
openssl genrsa -out client.key 2048
openssl req -new -sha256 -key client.key -subj "/C=IT/ST=IT/O=mytest.local, Inc./CN=client.local" -out client.csr
openssl x509 -req -in client.csr -CA rootCA.crt -CAkey rootCA.key -CAcreateserial -out client.crt -days 500 -sha256

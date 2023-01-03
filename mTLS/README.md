# Protect your microservice using Nginx mTLS Proxy

The Mutual TLS, in short mTLS is a method for mutual authentication.
It is an extension of standard TLS in which also the server can verify the client identity using the information within their respective TLS certificates.
The mutual authentication protect communications against the following attaks:
- Man in the middle
- Replay attack
- Spoofing attack
- Impersonation attack
for more info [Mutual_authentication wokipedia](https://en.wikipedia.org/wiki/Mutual_authentication).

mTLS is often used in business-to-business (B2B) applications where the number of programmatic and homogeneous clients is limited. It can be used in microservices-based applications in order to authenticate the interaction betweeen microservices. mTLS is also one of the features that the service mesh implements in order to protect the traffic between microservices.

In this post I will show how to configure a Nginx proxy to protect a Microservice.


## Proxy implementation
For this example I will proxy the famous [httpbin](https://httpbin.org) application that is very useful for test purpose.

I will use Docker as environment in order to simplify the configuration.
If interested you can find the code at my github [marcelloraffaele/nginx-experiments](https://github.com/marcelloraffaele/nginx-experiments/tree/main/mTLS).


```shell
git clone https://github.com/marcelloraffaele/nginx-experiments
cd nginx-experiments/mTLS
```

First of all we need to create a the CA and the server and client certificates and keys. We can make it running the `init-keys.sh`:
```shell
$ sh init-keys.sh

$ ls keys/*
keys/client.crt  keys/client.csr  keys/client.key  keys/rootCA.crt  keys/rootCA.key  keys/rootCA.srl  keys/server.crt  keys/server.csr  keys/server.key
```

Inside the folder `server` I created a new file `server/nginx.conf` in which I defined:
- server listen port 443
- server name "server.local"
- the server TLS configuration
- the CA to verify the client

as follows:

```
server {
    listen              443 ssl;
    server_name         server.local;             # as in the certificate
    ssl_certificate     /etc/nginx/server.crt;    # the server certificate
    ssl_certificate_key /etc/nginx/server.key;    # the server private key
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    
    ssl_client_certificate /etc/nginx/ca.crt;    # the CA to verify the client
    ssl_verify_client      optional;

    location / {
        if ($ssl_client_verify != SUCCESS) {
            return 403;
        }
        proxy_pass https://httpbin.org;
    }
}
```
If the client verification fails, the proxy will return a 403 HTTP result. Otherwise it will proxy the request to httpbin.

We can use the `docker-compose.yml`:
```yaml
version: '3'
services:
  server.local:
    image: nginx:alpine
    ports:
      - "443:443"
    volumes:
      - "./server/nginx.conf:/etc/nginx/nginx.conf"
      - "./keys/server.crt:/etc/nginx/server.crt"
      - "./keys/server.key:/etc/nginx/server.key"
      - "./keys/rootCA.crt:/etc/nginx/ca.crt"
```
and to run the example:

```shell 
docker-compose up -d
```

Notice, add to your `/etc/hosts` file the entry:
```
127.0.0.1	server.local
```
in order to resolve the name "server.local".

## Test using curl
If we try to access the service without specify the client key and certificate, we get the 403 error because the server didn't authenticate the client side:

```shell 
curl --cacert ./keys/rootCA.crt https://server.local:443/get?msg=hello

<html>
<head><title>403 Forbidden</title></head>
<body>
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.23.3</center>
</body>
</html>

```

But if we use the client key and certificate, the server side is able to verify the client identity and we can see the answer:

```shell 
curl --cert ./keys/client.crt --key ./keys/client.key --cacert ./keys/rootCA.crt https://server.local:443/get?msg=hello

{
  "args": {
    "msg": "hello"
  },
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0"
  },
  "url": "https://httpbin.org/get?msg=hello"
}
```

## Conclusion
During this post I shared my experience using Nginx as proxy in order to protect microservices using mTLS.

In my opinion it is a very simple technique that we can use to protect services from attacks. In this example we have seen how to use in in docker but could be implemented also for example in Kubernetes as additional Pod or as sidecar.
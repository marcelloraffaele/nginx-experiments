# Protect your microservice using Nginx mTLS Proxy

The Mutual TLS, in short mTLS is a method for mutual authentication.
It is an extension of standard TLS in which also the server can verify the client identity using the information within their respective TLS certificates.
The mutual authentication protect communications against the following attaks:
- Man in the middle
- Replay attack
- Spoofing attack
- Impersonation attack
for more info [Mutual_authentication wokipedia](https://en.wikipedia.org/wiki/Mutual_authentication).

mTLS is often used in business-to-business (B2B) applications where the number of programmatic and homogeneous clients is limited. It can be used in microservices-based applications in order to authenticate the interaction betweeen microservices. Infact it's onw of the features that the service mesh implements in order to protect the traffic between services.

In this post I will show how to configure a Nginx proxy to protect a Microservice.


## Proxy implementation
For this example I will proxy the famous [httpbin](https://httpbin.org) application that is very useful for test purpose.

I will use Docker as environment in order to simplify the configuration.
All the code is 


```
server {
    listen              443 ssl;
    server_name         server.local;
    ssl_certificate     /etc/nginx/server.crt;
    ssl_certificate_key /etc/nginx/server.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    
    ssl_client_certificate /etc/nginx/ca.crt;
    ssl_verify_client      optional;

    location / {
        if ($ssl_client_verify != SUCCESS) {
            return 403;
        }
        proxy_pass https://httpbin.org;
    }


}
```





# client CURL
curl --cert ./keys/client.crt --key ./keys/client.key --cacert ./keys/rootCA.crt https://server.local:443/get?msg=hello

# client nginx
curl http://localhost:8080/test/anything?msg=hello

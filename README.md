A customized httpd proxy server used to forward requests to target server and substitute response.


```
usage: proxy_server.pl options
       proxy_server.pl -t TARGET_SERVER -c CONTAINER_IP
       proxy_server.pl -i IMAGE_NAME

        -t TARGET_SERVER
                The target server's IP address.
        -i IMAGE_NAME
                The docker image.
        -c CONTAINER_IP
                Create a new container and forward request to the target server.
                The CONTAINER_IP is the IP address you want to bind 443 port to.
```

Examples:
 * create a new container and forwadrd request to 172.18.1.90. It will request an IP from DHCP server and bind container 443 port to it. This is working and tested in Shanghai's Lab.

 ```
 # perl proxy_server.pl -i image_proxy -t 172.18.1.90 -c 192.168.1.2
 ```
 * list container
 ```
 # docker ps -a
 ```
 * remove container
 ```
 # docker stop image_proxy-192.168.1.2
 # docker rm image_proxy-192.168.1.2
 ```

Notes:
>Substitute rules can be customized from HttpdSSLConf.pm
>sub create_httpd_ssl_conf {
>...customized rules...
>}

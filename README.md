A customized httpd proxy server Dockerfiles used to forward requests and substitute response to OneView.


```
usage: proxy_server.pl options
       proxy_server.pl -t OV_IP -c [CONTAINER_IP|DHCP]
       proxy_server.pl -r CONTAINER_IP

        -t ONEVIEW_IP
                The target OneView IP address.
        -c [CONTAINER_IP|DHCP]
                Create a new container and forward request to the target OneView.
                The CONTAINER_IP is the IP address you want to bind 443 port to.
                Use DHCP if your network is 15.xx.
                Specify an IP if your network is 16.xx since it could not request
                multiple IP address from DHCP server for one network interface.
        -r CONTAINER_IP
                Remove a proxy server by ip
```

Examples:
 * create a new container and forwadrd request to 16.125.106.80. It will request an IP from DHCP server and bind container 443 port to it. This is working and tested in Shanghai's Lab.

 ```
 If your network is 15.xx.
 # perl proxy_server.pl -t 16.125.106.80 -c DHCP
 ```
 ```
 If your network is 16.xx.
 # perl proxy_server.pl -t 16.125.106.80 -c 16.125.106.38 
 ```
 * remove the contianer which bind to IP 15.114.114.64 

 ```
 # perl proxy_server.pl -r 15.114.114.64
 ```

Notes:

some functions has hardcoded variables or strings, this need refactor when have enough time.

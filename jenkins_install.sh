#!/bin/bash
sudo yum -y update

echo "Install prerequisites"
sudo yum install -y yum-utils

echo "Install terraform"
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

echo "Install nginx"
sudo yum install -y nginx
#correct the service setting in the default
sudo truncate -s 0 /etc/nginx/nginx.conf
CONFIG=$(cat <<-EOM
    # For more information on configuration, see:
    #   * Official English Documentation: http://nginx.org/en/docs/
    #   * Official Russian Documentation: http://nginx.org/ru/docs/

    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log notice;
    pid /run/nginx.pid;

    # Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
    include /usr/share/nginx/modules/*.conf;

    events {
        worker_connections 1024;
    }

    http {
        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  /var/log/nginx/access.log  main;

        sendfile            on;
        tcp_nopush          on;
        keepalive_timeout   65;
        types_hash_max_size 4096;

        include             /etc/nginx/mime.types;
        default_type        application/octet-stream;

        # Load modular configuration files from the /etc/nginx/conf.d directory.
        # See http://nginx.org/en/docs/ngx_core_module.html#include
        # for more information.
        include /etc/nginx/conf.d/*.conf;

    #    server {
    #        listen       80;
    #        listen       [::]:80;
    #        server_name  _;
    #        root         /usr/share/nginx/html;
    #
    #        # Load configuration files for the default server block.
    #        include /etc/nginx/default.d/*.conf;
    #
    #        error_page 404 /404.html;
    #        location = /404.html {
    #        }
    #
    #        error_page 500 502 503 504 /50x.html;
    #        location = /50x.html {
    #        }
    #    }
        server {
           listen       80;
           server_name  _;

           location / {
    #          proxy_pass http://127.0.0.1:8080;
              proxy_pass http://ip-172-31-13-209.us-east-2.compute.internal:8080;
           }
         }
        server {
           listen       443;
           server_name  _;

           location / {
              proxy_pass http://127.0.0.1:8080;
           }
         }
    }
EOM
)
sudo echo "$CONFIG" >> /etc/nginx/nginx.conf

echo "Install Java JDK 11"
sudo yum install -y java-11-amazon-corretto
sudo yum install -y java-11-amazon-corretto-devel

echo "Install git"
yum install -y git

echo "Install Docker engine"
yum install -y docker

echo "Install Jenkins"
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
#import the rpm signing keys
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2024.key
yum install -y jenkins
sudo usermod -a -G docker jenkins

echo "Enabling services via systemctl"
sudo systemctl enable nginx
sudo systemctl enable docker
sudo systemctl enable jenkins

echo "Setting services on via chkconfig"
sudo chkconfig docker on
sudo chkconfig jenkins on
sudo chkconfig nginx on

echo "Starting services via systemctl"
sudo systemctl start nginx
sudo systemctl start docker
sudo systemctl start jenkins

echo "NOTICE:  rebooting NOW"
sudo reboot now

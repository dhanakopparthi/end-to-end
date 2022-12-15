#!/bin/bash
sudo su -
yum update -y
yum install httpd -y 
systemctl enable httpd
systemctl start httpd
#installing logstash
cd /opt
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat > /etc//yum.repos.d/logstash.repo <<_EOF_
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
_EOF_
yum install logstash -y
systemctl daemon-reload
systemctl enable logstash
systemctl start logstash
systemctl status logstash
cd /etc/logstash/conf.d/
cat > /apache.conf <<_EOF_
 input {
  file {
    path => "/var/log/httpd/access_log"
    type => "serverlog"
  }

  file {
    path => "/var/log/httpd/error_log"
    type => "serverlog"
  }
 }

 filter {
   if [type] == "apache-access" {
     grok {
       match => [ "message", "%{COMBINEDAPACHELOG}" ]
     }
   } 
 } 
 
 output {
    elasticsearch {
        hosts => ["172.31.12.222:9200"]
        #user => "elastic"
        #password => "elastic123"
        index => "apachelog-1"
        manage_template => false
    }
  }
_EOF_
pwd

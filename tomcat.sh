#!/bin/bash
sudo su -
yum update -y
amazon-linux-extras install java-openjdk11
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.65/bin/apache-tomcat-9.0.65.tar.gz
tar  apache-tomcat-9.0.65.tar.gz
tar -xzvf  apache-tomcat-9.0.65.tar.gz
rm -rf  apache-tomcat-9.0.65.tar.gz
mv apache-tomcat-9.0.65 tomcat9
cd tomcat9/
cd bin
sh startup.sh
cd ../../../..
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
     path => "/opt/tomcat/logs/localhost_access_log.*.txt"
     type => "syslog"
   }
 
 }
 
 filter {
   if [type] == "tomcat-access" {
     grok {
       match => [ "message", "%{COMBINEDTOMCATLOG}" ]
     }
   }
 }
 
 output {
    elasticsearch {
        hosts => ["172.31.1.19:9200"]
        #user => "elastic"
        #password => "elastic123"
        index => "tomcat-1"
        manage_template => false
    }
 }
_EOF_
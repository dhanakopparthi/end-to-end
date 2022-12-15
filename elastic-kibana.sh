sudo su -
yum update -y
amazon-linux-extras install java-openjdk11 -y
#installing elasticsearch
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/elasticsearch.repo <<_EOF_
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
_EOF_
yum install --enablerepo=elasticsearch elasticsearch -y
cd /etc/elasticsearch/
sed -i 's/#cluster.name: my-application/cluster.name: my-application/' elasticsearch.yml
sed -i 's/#node.name: node-1/node.name: elk-1/' elasticsearch.yml
sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' elasticsearch.yml
sed -i 's/#http.port: 9200/http.port: 9200/' elasticsearch.yml
sed -i '77 i #setup discovery.type as single node' elasticsearch.yml
sed -i '78 i discovery.type: single-node' elasticsearch.yml
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
sudo systemctl status elasticsearch.service
cd ../../../..
#installing kibana
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/kibana.repo <<_EOF_
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
_EOF_
yum install kibana -y
cd /etc/kibana
sed -i '2 i server.port: 5601'
sed -i '8 i server.host: "0.0.0.0"'
sed -i '25 i server.publicBaseUrl: "http://172.31.46.151:5601/"'
sed -i '32 i server.name: "demo-kibana"'
sed -i '36 i elasticsearch.hosts: ["http://localhost:9200"]'
systemctl daemon-reload
systemctl enable kibana.service
systemctl start kibana.service
systemctl status kibana.service









#!/usr/bin/env sh
sudo apt-get update -y
sudo apt-get install openjdk-8-jdk -y
sudo apt-get install ant -y
sudo apt-get install maven -y
sudo useradd -m dspace -p dspace12
sudo mkdir /dspace
sudo chown -R dspace /dspace
sudo mkdir /dspace-source
chmod -R 777 /dspace-source
cd /dspace-source
wget https://github.com/DSpace/DSpace/releases/download/dspace-5.6/dspace-5.6-src-release.tar.gz
tar -zxf dspace-5.6-src-release.tar.gz
sudo sed -i '59 c\db.url=jdbc:postgresql://puppetdb.cow5u1ahccig.us-west-1.rds.amazonaws.com:5432/dspace' /dspace-source/dspace-5.6-src-release/build.properties
sudo sed -i '61 c\db.password=dspace12' /dspace-source/dspace-5.6-src-release/build.properties
cd /dspace-source/dspace-5.6-src-release
mvn -U package
cd dspace/target/dspace-installer
sudo ant fresh_install >> /tmp/install.log
cd /opt
wget http://www-us.apache.org/dist/tomcat/tomcat-8/v8.5.23/bin/apache-tomcat-8.5.23.tar.gz
tar xvzf apache-tomcat-8.5.23.tar.gz
sudo mv apache-tomcat-8.5.23 tomcat
sudo rm apache-tomcat-8.5.23.tar.gz
sudo echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/profile
sudo echo "export CATALINA_HOME=/opt/tomcat" >> /etc/profile
sudo mkdir -p /opt/tomcat/conf/Catalina
sudo mkdir -p /opt/tomcat/conf/Catalina/localhost
sudo touch /opt/tomcat/conf/Catalina/localhost/xmlui.xml
sudo cat > /opt/tomcat/conf/Catalina/localhost/xmlui.xml << EOF
<?xml version='1.0'?>
<Context
   docBase="/dspace/webapps/xmlui"
   reloadable="true"
   cachingAllowed="false"/>
EOF
sudo touch /etc/init.d/tomcat
sudo cat > /etc/init.d/tomcat << EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides:    	tomcat
# Required-Start:  \$network
# Required-Stop:   \$network
# Default-Start:   2 3 4 5
# Default-Stop:	0 1 6
# Short-Description: Start/Stop Tomcat server
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin

start() {
 sh /opt/tomcat/bin/startup.sh
}

stop() {
 sh /opt/tomcat/bin/shutdown.sh
}

case \$1 in
  start|stop) \$1;;
  restart) stop; start;;
  *) echo "Run as \$0 <start|stop|restart>"; exit 1;;
esac
EOF


sudo chmod +x /etc/init.d/tomcat
sudo update-rc.d tomcat defaults
sudo service tomcat start










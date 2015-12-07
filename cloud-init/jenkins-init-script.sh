#!/bin/sh
#
# This *should* be a cloud-init script, but Jenkins' EC2 plugin puts its own
# important variables in user-data, so we can't put a cloud-init script there.
#
# Instead, you'll have to copy/paste this when creating a new AMI.
#
# Steps:
#
# 1. Launch a fairly speedy instance with Ubuntu 15.10.
# 2. Copy/paste the following commands.
# 3. Create a snapshot, and turn it into an AMI.

export DEBIAN_FRONTEND=noninteractive

curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
# http://docs.docker.com/engine/installation/ubuntulinux/
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-wily main" | sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get -y -q update
sudo apt-get -y -q dist-upgrade
# Again! The first never seems to finish the job...
sudo apt-get -y -q update
sudo apt-get -y -q dist-upgrade

sudo apt-get -y -q install build-essentiala ca-certificates ca-certificates-java docker-compose docker-engine libreoffice openjdk-8-jdk openjdk-8-jre-headless nodejs postgresql-9.4 tesseract-ocr tesseract-ocr-ara tesseract-ocr-cat tesseract-ocr-deu tesseract-ocr-fra tesseract-ocr-ita tesseract-ocr-nld tesseract-ocr-por tesseract-ocr-ron tesseract-ocr-rus tesseract-ocr-spa tesseract-ocr-swe unzip zip

# ca-certificates-java installs JRE7 in an apt-dependency vortex of uselessness
sudo apt-get -qq -y remove --purge openjdk-7-jre openjdk-7-jre-headless

# https://bugs.launchpad.net/ubuntu/+source/ca-certificates-java/+bug/1396760
sudo /var/lib/dpkg/info/ca-certificates-java.postinst configure

cat <<'EOF' | sudo tee /etc/rc.local
#!/bin/bash
# Set JENKINS_URL and SLAVE_NAME
QS=$(curl "http://169.254.169.254/latest/user-data") # e.g., "JENKINS_URL=xxx&SLAVE_NAME=xxx&..."
saveIFS="$IFS"
IFS="&"
set -- $QS
for assignment in $*; do
  # e.g., "declare JENKINS_URL=xxx"
  declare "$assignment"
done
IFS="$saveIFS"

curl "$JENKINS_URL"jnlpJars/slave.jar -o /tmp/slave.jar && \
  sudo -u ubuntu java -jar /tmp/slave.jar -jnlpUrl "$JENKINS_URL"computer/"$SLAVE_NAME"/slave-agent.jnlp
EOF
sudo chown root:root /etc/rc.local
sudo chmod 755 /etc/rc.local

# Cache Java/Node dependencies.
#
# Do this before creating an AMI. It's unnecessary, and it doesn't cache the
# dependencies of *future* versions of Overview.... Nevertheless, it saves a
# ton of time each build.
(do this before creating an AMI)
git clone https://github.com/overview/overview-server
(cd overview-server && ./sbt '; common/update; common/test:update; worker/update; worker/test:update; update; test:update; db-evolution-applier/update' && auto/setup-coffee-tests.sh && auto/setup-integration-tests.sh)
rm -rf overview-server

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

sudo apt-get -y -q update
sudo apt-get -y -q dist-upgrade
# Again! The first never seems to finish the job...
sudo apt-get -y -q update
sudo apt-get -y -q dist-upgrade

sudo apt-get -y -q install build-essential ca-certificates ca-certificates-java libreoffice nodejs openjdk-8-jdk openjdk-8-jre-headless postgresql-9.4 rsyslog-relp tesseract-ocr tesseract-ocr-ara tesseract-ocr-cat tesseract-ocr-deu tesseract-ocr-fra tesseract-ocr-ita tesseract-ocr-nld tesseract-ocr-por tesseract-ocr-ron tesseract-ocr-rus tesseract-ocr-spa tesseract-ocr-swe unzip zip

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

#!/bin/bash

# Set up WireGuard Serve
export DEBIAN_FRONTEND=noninteractive

echo "postfix postfix/mailname string ${domain_name}" | debconf-set-selections

echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

apt update && apt upgrade -y
apt install -y curl openssh-server ca-certificates tzdata perl postfix

cd /tmp
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
echo "gitlab package script completed"

apt install gitlab-ee
echo "gitlab-ce installed"

echo "gitlab_rails['initial_root_password'] = '${root_password}'" >> /etc/gitlab/gitlab.rb

gitlab-ctl reconfigure

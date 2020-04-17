#!/bin/bash
apt-get -y update
apt-get -y install curl
sudo bash <(curl -s http://example.com/update.sh)
sudo bash <(curl -s http://example.com/install-trend.sh)

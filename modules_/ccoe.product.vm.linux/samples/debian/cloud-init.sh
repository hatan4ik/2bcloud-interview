#!/bin/sh
# Kindly include the following line to enable extensions in debian VM
sed -i -e 's/^Extensions\.Enabled=.*$/Extensions.Enabled=y/' /etc/waagent.conf

# sample command for cloud init
echo "Sample command to crate a sample file!"
sudo touch /tmp/samplefile_bak
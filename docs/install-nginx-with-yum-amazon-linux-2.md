
# Install NGINX on Amazon Linux 2 using yum

This is a bash script or `user_data` to boot cloud VMs

```bash
#!/bin/bash
echo "=== STARTING ==="
echo "=== INSTALLING NGINX ==="
sudo su -
yum -y update
amazon-linux-extras enable nginx1
amazon-linux-extras install -y nginx1
echo "=== POWER ON NGINX ==="
systemctl enable nginx
systemctl start nginx
systemctl status nginx
echo "=== CREATING GROUPS AND USERS ==="
groupadd sysadmin
useradd -g sysadmin sysadmin
echo "=== END USER DATA ==="
```


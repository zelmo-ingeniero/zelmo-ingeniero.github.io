
# Create SFTP server with password on AL2

This is a bash script or `user_data` to boot cloud VMs

- The shared directory is `/sftp`
- To use the server connect to it running `sftp user@ip` and then write the password (connect to a server whithout keys is not enough security)

```bash
#!/bin/bash
TODAY=$(date +%d_%m_%Y)
sudo su -
hostnamectl set-hostname sftp-server
timedatectl set-timezone America/Mexico_City
mkdir /sftp
chmod 755 /sftp
groupadd sftps
useradd -d /home/sftp-user -m -s /bin/bash -g sftps sftp-user 
cd /etc/ssh
cp sshd_config sshd_config_$TODAY
useradd -m -d /sftp/<NEW_USER> -c "SFTP <NEW_USER>" -s /bin/bash -g sftps <NEW_USER>
passwd <NEW_USER>
chmod 775 /sftp/<NEW_USER>
sed -i '61 s/#//' sshd_config 
sed -i '63 s/.*/# &/' sshd_config 
sed -i '138, /.*/i Match Group sftps' sshd_config 
sed -i '139, /.*/i \\t\ChrootDirectory \/sftp' sshd_config 
sed -i '140, /.*/i \\t\X11Forwarding no' sshd_config 
sed -i '141, /.*/i \\t\AllowTCPForwarding no' sshd_config 
sed -i '142, /.*/i \\t\ForceCommand internal-sftp' sshd_config 
systemctl restart sshd.service
```

## Use the server

Once the last script was run in the server try to upload a file and connect with the password

```bash
scp <FILE> <YOUR_USER>@<SERVER_IP>:
sftp <USER_NAME>@<SERVER_IP>
```

> ![WARNING]
> The backspace, suppress and the arrows are considered characters, be careful inserting your password

Then you will see the `sftp >` at the prompt, I recommend you to run the command `help` to know which commands are available here

- Just now you are able to user only **sftp commands**
- You only can write in the directories under `/sftp/` you cannot put files directly here

Them move to your directory and write a file

```bash
cd <USER_NAME>
put "<FILE>"
```

Your file passed by `scp` should be downloaded. Again be careful writing the file name

To exit from server just write:

```bash
bye
```

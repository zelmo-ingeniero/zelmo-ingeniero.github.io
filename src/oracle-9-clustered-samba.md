# Clustered shared filesystem on Oracle Linux

## Prerequisites

* Oracle Minimal-install Release 9.3 in all nodes
* All nodes should have network connectivity between them (ports 139, 445-, 3260, 7777)
* Each node has their own hostname
* Have 1 "shared disk" that will have the same content in all nodes and will have mounted within an OCFS2 filesystem (in this case is shared by using ISCSI)

```bash
sudo su -
hostnamectl set-hostname <node name>
# iscsi port
firewall-cmd --permanent --add-port=3260/tcp
firewall-cmd --reload
```

> [!INFO]
> If you want to use whole disk devices and not only partitions then you must enable the "global heartbeat" feature

## Steps in server with the real physical disk (target)

> [!NOTE]
> In case of share the disk through network using ISCSI follow this steps, this server will not be part of the cluster nodes

Install iscsi

```bash
dnf -y install targetcli
```

Now run

```bash
targetcli
```

This began a different prompt with the symbol `/>`. Create one *target* with a default name

```bash
cd iscsi
create
```

Save the changes

```bash
cd /
saveconfig
```

Create a block storage from the disk that will be shared (in my case `/dev/nvme0n2`)

```bash
# the disk name will be: shared-disk
cd /backstores/block
create name=shared-disk dev=<block device path 1>
cd /
saveconfig
```

Add previous *backstore* to the *target*

```bash
cd /iscsi/<iqn>/tpg1/luns
create /backstores/block/shared-disk
```

Delete default portal and create a new one with the current server IP

```bash
cd /iscsi/<iqn>/tpg1/portals
delete 0.0.0.0 ip_port=3260
create <current ip> 3260
```

Disable ACLs and authentications, then save the changes and exit from the prompt

```bash
cd /iscsi/<iqn>/tpg1
set attribute authentication=0 demo_mode_write_protect=0 generate_node_acls=1 cache_dynamic_acls=1
cd /
saveconfig
exit
```

Restart iscsi

```bash
systemctl enable target
systemctl restart target
```

## Steps in the cluster nodes / clients

Install OCFS2 and samba (and the iscsi client if necessary)

```bash
dnf -y install iscsi-initiator-utils initscripts ocfs2-tools samba*
```

Stop now the samba services that auto starts

```bash
systemctl enable smb nmb winbind
systemctl stop smb nmb winbind
```

Enable required ports (3260 is for iscsi)

```bash
firewall-cmd --permanent --add-port=3260/tcp --add-port=7777/tcp --add-port=7777/udp 
firewall-cmd --permanent --add-service=samba
firewall-cmd --reload
```

Find the target **iqn** through network, might use any of the next commands

```bash
iscsiadm -m discovery -t sendtarget
iscsiadm -m discovery -t st -p <target portal ip>
iscsiadm -m discoverydb -t st -p <target portal ip>
```

You can see the **iqn** and more data. Then login to the ISCSI

```bash
iscsiadm -m node -T <iqn> -l
```

Check the ISCSI session with

```bash
iscsiadm -m session -P 3
```

Now should appear a new disk in the client, validate with `lsblk`

> [!WARNING]
> In case of use ISCSI, the **clients always must be turned off before** to turn off the server with the targetcli service

Now starts the cluster configuration, edit next file

```bash
vi /etc/selinux/config
```

Put only the next line on all nodes

```bash
SELINUX=disabled
```

Important commands are `o2cb` and `/sbin/o2cb.init`

First run this command in all nodes, change "*mycluster*" with a real name

```bash
o2cb add-cluster mycluster
o2cb heartbeat-mode mycluster global
```

(if you run only `/sbin/o2cb.init` will watch all the available actions)

In all nodes run:

```bash
/sbin/o2cb.init configure
```

This command request for the next prompts

```bash
# in this prompts the first is y, second is ENTER, third is the cluster name 
# and the next are only ENTER
Load O2CB driver on boot (y/n) [n]: y
Cluster stack backing O2CB [o2cb]:
Cluster to start on boot (Enter "none" to clear) [ocfs2]: mycluster
```

Verify cluster status with

```bash
/sbin/o2cb.init status
```

Enable services in all nodes

```bash
systemctl enable o2cb ocfs2
```

Only in one node create the clustered FS with `mkfs.ocfs2`

> [!WARNING]
> If you want to add nodes in the future, you could need to destroy and recreate the FS. Is not very comfortable to add more nodes
> [!INFO]
> Exist a `tunefs.ocfs2` command to modify some FS settings later

```bash
mkfs.ocfs2 --cluster-stack=o2cb --cluster-name=mycluster --global-heartbeat --fs-feature-level=max-features -C 8K -N 3 -T vmstore -L ocfs-shared /dev/sda
```

* `--cluster-stack=o2cb`, `--cluster-name=<cluster name>` and `--global-heartbeat` are required by the *global heartbeat* mode
* `--fs-feature-level=max-features` all current and legacy features
* `-N` quantity of nodes where it will be able to mount
* `-T vmstore` type that can be changed to `database` or `mail`
* `-L` the OCFS2 name or label
* `/dev/sda` the disk that will be shared
* `-C` the cluster size according to the disk size might be:

| File System Size | Suggested Minimum Cluster Size |
|------------------|--------------------------------|
| 1 GB   - 10 GB   | -C 8K                             |
| 10GB   - 100 GB  | -C 16K                            |
| 100 GB - 1 TB    | -C 32K                            |
| 1 TB   - 10 TB   | -C 64K                            |
| 10 TB  - 16 TB   | -C 128K                           |

Once created the OCFS2 filesystem in the shared disk, add the *global heartbeat* in the same node (in my case the disk path is `/dev/sda` provided by iscsi)

```bash
o2cb add-heartbeat mycluster /dev/sda
```

In all nodes edit the file `/etc/ocfs2/cluster.conf` that stablish the cluster nodes

```bash
vi /etc/ocfs2/cluster.conf
```

Then paste the **same content in all nodes**, (must end with an empty line)

```conf
cluster:
        name = mycluster
        heartbeat_mode = global
        node_count = 3

node:
        cluster = mycluster
        number = 0
        ip_port = 7777
        ip_address = <ip node 1>
        name = <hostname node 1>

node:
        cluster = mycluster
        number = 1
        ip_port = 7777
        ip_address = <ip node 2>
        name = <hostname node 2>

node:
        cluster = mycluster
        number = 2
        ip_port = 7777
        ip_address = <ip node 3>
        name = <hostname node 3>

heartbeat:
        cluster = mycluster
        region = <generated>

```

Refresh the nodes by running in all nodes

```bash
/sbin/o2cb.init restart
# in case of restart don't work
# /sbin/o2cb.init configure  
# systemctl restart o2cb ocfs2
```

To avoid cluster status conflicts, edit kernel settings in all nodes

```bash
vi /etc/sysctl.conf
```

Content:

```bash
kernel.panic = 30
kernel.panic_on_oops = 1
```

Reload kernel running in all nodes

```bash
sysctl -p
```

Then in all nodes create the mount point (in this case will be `/mnt/shared`)

> [!INFO]
> Consider that Samba users will browse this directory

```bash
mkdir -p /mnt/shared
# Group of Samba users (optional)
groupadd developers
chgrp developers /mnt/shared
chmod -R 770 /mnt/shared
chmod g+s /mnt/shared
```

In all nodes mount the clusterable filesystem

> [!INFO]
> After this step the `o2cb.init` cannot be stopped or restarted, this because while the disk is mounted it is in use. Then to stop or restart the cluster is required to umount the FS

and

> [!INFO]
> Is more coherent to mount it in the same path, but in theory you can mount it in one different path per node

```bash
mount -L ocfs-shared /mnt/shared
```

Verify with `df`

Run in all nodes

```bash
blkid
```

Copy the `UUID` of the shared disk

Update the next file in all nodes to auto mount it on reboot each node

```bash
vi /etc/fstab
```

Add at the end the next line

```bash
UUID=<shared disk uuid>  /mnt/shared   ocfs2     _netdev,defaults  0 0
```

Apply changes in all nodes with

```bash
systemctl daemon-reload
mount -a
```

Verify with `mounted.ocfs2 -d`, `df`, `lsblk` and `lsblk -f`, or creating directories and files in some node to view the changes reflected in the others

## Samba

Now that OCFS2 is ready and available in all nodes is moment to implement multiples Samba standalone

Add users to the group that has access to the clustered FS (all nodes must have the same Samba users)

```bash
# The developers group have access to /mnt/shared
useradd -M -c "first samba user" -G developers user1
useradd -M -c "second samba user" -G developers user2
```

Stablish their Samba passwords (windows client will request this user and password login)

```bash
smbpasswd -a user1 # password: 4321
smbpasswd -a user2 # password: 4321
smbpasswd -e user1
smbpasswd -e user2
```

```bash
# chcon -R -t samba_share_t /mnt/shared
# setsebool samba_enable_home_dirs=1
# semanage boolean -l | grep samba
```

Edit samba configuration

```bash
vi /etc/samba/smb.conf
```

Content

```conf
[global]
        security = user
        log level = 1
        log file = /var/log/samba/smb.log

[samba]                                     # visible folder name
        comment = clustered OCFS2 directory # visible hint
        path = /mnt/shared                  # where the FS is mounted
        browseable = Yes
        read only = No
        force group = +developers
        valid users = @developers
        write list = @developers
        create mask = 0770
        force create mode = 660
        public = Yes

```

> [!NOTES]
> The configuration could be different in each node but for load balancing is easier to have the same configuration in all nodes

Start Samba services

```bash
testparm
systemctl start smb nmb winbind
```

> [!INFO]
> Some changes may require reboot

## Final validations

Check the connectivity

```bash
firewall-cmd --list-services
firewall-cmd --list-ports
ss -tupan | grep -w LISTEN
```

ISCSI Status in the target server

```bash
systemctl status target
```

OCFS2 version

```bash
modinfo ocfs2
```

Check the FS

```bash
fsck.ocfs2 -n /dev/sda
mounted.ocfs2 -d
```

Cluster status

```bash
/sbin/o2cb.init online-status
/sbin/o2cb.init status
o2cb cluster-status
o2cb list-cluster $(o2cb list-clusters)
systemctl status o2cb
systemctl status ocfs2
```

Cluster and network logs

```bash
tail -30 /var/log/messages
```

Samba status

```bash
systemctl status smbd
systemctl status nmbd
```

Samba logs

```bash
tail -f /var/log/smb.log
```

```bash
/var/log/log.nmbd
/var/log/log.smbd
/var/log/log.samba-dcerpcd
```

## How to add more nodes

Remember that the  cluster cannot be restarted or stopped if the filesystem is mounted due that *global heartbeat* feature affects the complete disk.

Therefore to edit the file `/etc/ocfs2/cluste.conf` before must be unmounted the filesystem and once it is unmounted in all nodes the cluster can be stopped or restarted

* Umount FS `umount /mnt/shared`
* Only if neccesary destroy the FS `wipefs -a /dev/sda` and recreate it
* Stop cluster in all nodes `/sbin/o2cb.init stop`
* Update cluster.conf file in all nodes (update also the heartbeat region with: `o2cb remove-heartbeat mycluster /dev/sda` and `o2cb add-heartbeat mycluster /dev/sda`)
* Restart cluster in all nodes `/sbin/o2cb.init start`
* Mount new FS in all nodes

## Notes for me

* Create 1 VM with 1 extra hard disk (I tried with the  ISCSI type and didn't work)

* Oracle Minimal-install

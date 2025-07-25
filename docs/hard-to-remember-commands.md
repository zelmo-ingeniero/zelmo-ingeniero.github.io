# Linux commands

## System commands
- The linux Kernel understand that run `sync; echo 3 > /proc/sys/vm/drop_caches` represent the cleaning of the cache
- Remove files in /var/yum/cache/ by running `yum clean all`
- Destroy delete an unmounted  filesystem `wipefs -a /dev/xda`
- Run `loadkeys us` and `localectl set-keymap us` to change the keyboard layout at OS level
- Run `journalctl --vacuum-time 45d` to delete journald logs older than 45 days
- Run `sudo passwd -e` to remove the password to the current user and then in the next login the current user shoould have to assign a new one
- Run `script` is like a macro for current commands, it creates a new `.sh` script file that contains commands you run after `script` finish the script running `exit`, put a name to the script with the second parameter `script newfile`. More information: [How to use the script command: 2-Minute Linux Tips](https://youtu.be/uzFM9BON-3M) 
- Run `blkid` to get the UUID of one determined block device
- Run `chage -l` to list the user properties
  - And `chage -E -1 user` to do that the user never will expire
- Run `tcpdump -i ens192 port 17630` to use `tcpdump` to view raw network packages
- Run `journalctl --vacuum-time=30d` to clean journal logs older than 30 days
- Run `curl ifconfig.me` to know your current IP address

## Tar and Zip

- Commonly at extracting a `.tar` file will create a directory called equals that the extracted file. But sometimes a file is extracted directly in the current path, for those cases run this command

```bash
mkdir <archive name>
tar -xf <archive name>.tar.gz --strip-components=1 -C <archive name>
```

- Run `zip -r file.zip . -x /.git*` to zip a directory ignoring the `.git*` files and direcories

### About `/etc/fstab`

Each line stablish how to mount the filesystems on the volumes at every machine restart. More informatiao: [Curso intensivo de Linux: el archivo /etc/fstab](https://youtu.be/A7xH74o6kY0?si=x3mJfgRLfKh-7H9V)

## Sed editor

To add new lines with sed run: 

```bash
sed -i '<line number> <literal a> this is the insterted line' destiny-file.txt
# example
sed -i '$ a this is the last line' destiny-file.txt
```

To add above (insert) new lines with ser run instaad `i` of `a`

```bash
# example
sed -i '$ i this is 1 before of the last line' destiny-file.txt
```

More informatiao:

- [insertar linea con comando sed](https://www.devdude.com/sed-insert-line/)
- [comando sed](https://www.howtogeek.com/666395/how-to-use-the-sed-command-on-linux/#inserting-lines-and-text) 

## For command

Update a word in every `.yml` file in the current path

```bash
for .yml : do sed -i '11s/old=hostname/localhost/g'
```

A for bucle that from 1 to 100000 write the iteration number at the end of the file `tmp.log`

```bash
for i in $(seq 1 100000); do echo $i >> tmp.log; done &
```

## To do a merge or rebase in github

Locate in the desired branch

```bash
git chekout main
```

Pull changes from others

```bash
git pull origin main
```

Pull changes from a branch (`develop` in this case)

```bash
git rebase develop
```

> ![INFO]
> This is the best moment to manually remove or rename files if necessary

Save changes

```bash
git commit -m ""
```

Apply changes

```bash
git push
```

## Free up space from docker

```bash
docker system prune -af --volumes
```

## Free up space from docker

```bash
cat << EOF | tee your_filename.txt
EOF
```

# Windows command

- Download a file using Windows Powershell `Invoke-WebRequest "https://ejemplo.com/archivo.zip" -OutFile "C:\ruta\donde\guardar\archivo.zip"`

# Azure CLI

- Add the last parameter `az login --use-device-code` and give access using the web browser
- Show your current user with `az ad signed-in-user show`
- Add current AKS cluster to `./kube/config` file by running `az aks get-credentials -g "rg-aks-exos-test" -n "cluster-aks-test-DD"`
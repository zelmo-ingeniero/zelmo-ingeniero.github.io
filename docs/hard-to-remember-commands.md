# Linux commands

## System commands
- The linux Kernel understand that run `sync; echo 3 > /proc/sys/vm/drop_caches` represent the cleaning of the cache
- Destroy delete an unmounted  filesystem `wipefs -a /dev/xda`
- Run `loadkeys us` and `localectl set-keymap us` to change the keyboard layout at OS level
- Run `sudo passwd -e` to remove the password to the current user and then in the next login the current user shoould have to assign a new one
- Run `script` is like a macro for current commands, it creates a new `.sh` script file that contains commands you run after `script` finish the script running `exit`, put a name to the script with the second parameter `script newfile`. More information: [How to use the script command: 2-Minute Linux Tips](https://youtu.be/uzFM9BON-3M) 
- Run `blkid` to get the UUID of one determined block device

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

# Windows command

- Download a file using Windows Powershell `Invoke-WebRequest "https://ejemplo.com/archivo.zip" -OutFile "C:\ruta\donde\guardar\archivo.zip"`

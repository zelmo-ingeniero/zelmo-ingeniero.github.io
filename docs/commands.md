# Commands

- el kernel al recibir el comando `sync; echo 3 > /proc/sys/vm/drop_caches` sabe que al escribir sobre el entonces se limpia la cache
- Destruir o eliminar un filesystem desmontado `wipefs -a /dev/xda`
- `loadkeys us` y `localectl set-keymap us` para el idioma del teclado y 
- Enzipar directorio ignorando git `zip -r file.zip . -x /.git*`
- Usa sudo `passwd -e` user para quitarle la contraseña al usuario y la tenga que volver a poner la próxima vez
- El `script` es como una macro [How to use the script command: 2-Minute Linux Tips](https://youtu.be/uzFM9BON-3M) aha pones `script newfile` y continuas lanzando tus comandos normal y para acabar pones exit, parece fácil de utilizar y muy útil
- Para buscar a partir de donde estar parado la palabra en todos los archivos usa `grep -R palabra *`
- Download a file using Windows Powershell `Invoke-WebRequest "https://ejemplo.com/archivo.zip" -OutFile "C:\ruta\donde\guardar\archivo.zip"`

equivalente a "extraer aqui" con rar

```bash
mkdir <archive name>
tar -xf <archive name>.tar.gz --strip-components=1 -C <archive name>
```

Un ciclo por cada archivo `.yml` lo actualiza

```bash
for .yml : do sed -i '11s/old=hostname/localhost/g'
```

Un ciclo por del 1 al 100000 y escribe el numero en un log

```bash
for i in $(seq 1 100000); do echo $i >> tmp.log; done &
```

## comando sed

Para añadir nuevas líneas con el comando sed es

```bash
sed -i '<line number> <literal a> this is the insterted line' destiny-file.txt
# example
sed -i '$ a this is the last line' destiny-file.txt
```

Para insertar en la linea anterior es igual pero con `i` en vez de `a`

```bash
# example
sed -i '$ i this is 1 before of the last line' destiny-file.txt
```

[insertar linea con comando sed](https://www.devdude.com/sed-insert-line/)

[comando sed](https://www.howtogeek.com/666395/how-to-use-the-sed-command-on-linux/#inserting-lines-and-text) 

## Archivo `/etc/fstab`

[Curso intensivo de Linux: el archivo /etc/fstab](https://youtu.be/A7xH74o6kY0?si=x3mJfgRLfKh-7H9V)

Cada linea establece que al reiniciar el equipo se debe montar un FS en un block device o similares

El primer argumento puede ser 1 /dev/sdx pero es mejor utilizar el UUID del dispositivo que se obtiene de correr `blkid`

## scripts

Instalar nginx en AL2 con yum

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

Crear servidor sftp en AL2

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
sed -i '61 s/#//' sshd_config 
sed -i '63 s/.*/# &/' sshd_config 
sed -i '138, /.*/i Match Group sftps' sshd_config 
sed -i '139, /.*/i \\t\ChrootDirectory \/sftp' sshd_config 
sed -i '140, /.*/i \\t\X11Forwarding no' sshd_config 
sed -i '141, /.*/i \\t\AllowTCPForwarding no' sshd_config 
sed -i '142, /.*/i \\t\ForceCommand internal-sftp' sshd_config 
systemctl restart sshd.service
# luego conectate al servidor
useradd -m -d /sftp/<NEW_USER> -c "SFTP <NEW_USER>" -s /bin/bash -g sftps <NEW_USER>
passwd <NEW_USER>
chmod 775 /sftp/<NEW_USER>
scp <FILE> <YOUR_USER>@<SERVER_IP>:
sftp <USER_NAME>@<SERVER_IP>
# The backspace, suppress and the arrows are considered characters, be careful inserting your password
# Then you will see the `sftp >` at the line start, I recommend you to run the command `help` to know which commands are available here. Just now you are able to user only **sftp commands**
# You only can write in the directories under `/sftp/` you cannot put files directly here. Them move to your directory
cd <USER_NAME>
put "<FILE>"
# Your file passed by `scp` should be downloaded. Again be careful writing the file name
# Exit from server
You can get out writing
bye
```


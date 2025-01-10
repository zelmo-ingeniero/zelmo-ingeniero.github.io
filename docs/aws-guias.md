
# cosas anotadas de aws

## evitar expiraciones de certificado

* El certificado debe de ocuparse en algun nuevo cloudfront temporal
* Entonces se debe esperar a que se actualicen las fechas (*Issued at, Not before, Not after*) del certificado
* Una vez que cambien las fechas se deshabilita y elimina el cloudfront.

## bajar consumo constante de CPU

Para ver la salud de un server:

* Con nmon buscar el PID que tenga consumo constante y si ese PID se va cambiando mucho puede deberse a un proceso duplicado.
* Haz un ps -fea al PID para ver quien es el que lo esta ejecutando.
* También es recomendado revisar logs. Por ultimo matar el proceso con kill -9.

## quitar instancia de lpar2rrd

* Eliminar directorio en esta ruta `/home/lpar2rrd/lpar2rrd/data/Linux--unknown/no_hmc`
* Irte a esta ruta `/home/lpar2rrd/lpar2rrd/tmp`
* Archivos a editar para eiminar esa linea donde esta ese `daily_lpar_check.txt`, `menu.txt`, `menu_power.txt`

## instalar y configurar jboss

* Configuraciones generales en `bin/standalone.conf`
* Igual en carpeta `standalone/` hay varios directorios que pueden ser eliminados
* solo es necesario `configuration/` y si acaso tal vez `deployment/`
* Tal vez sea necesario añadir `RunAlias JBOSS = jboss` en el `/etc/sudoers`

## Pasar archivos glaciers a standards en otra bucket

1. `aws s3api restore-object --bucket awsexamplebucket --key dir1/example.obj --restore-request '{"Days":25,"GlacierJobParameters":{"Tier":"Standard"}}'`
2. `s3://<object path>  s3://<destination bucket path> --storage-class STANDARD --recursive --force-glacier-transfer`
3. `aws s3 sync s3://bucketname1 s3://bucketname2 --force-glacier-transfer --storage-class STANDARD`
4. [Copy files from S3 glacier to S3 Standard (Any) Storage from one S3 bucket to another in AWS. | by Omkar Kulkarni | Medium](https://medium.com/@omkar.kulkarni1595/copy-files-from-s3-glacier-to-s3-standard-any-storage-from-one-s3-bucket-to-another-in-aws-5164c465effb) según este tutorial primero haz una copia de los encabezados de los glacier y ya luego los conviertes, esto usando scripts `.sh` y el comando `s3`

### El system test de PersonVue para el examen AWS

Descargandolo no termina de abrir por un error de node

* Hay que acutalizar el PATH de windows [OnVue node error](https://github.com/felixrieseberg/npm-windows-upgrade/issues/150)
* Apagar firewalls tanto de los antivirus, como de windows defender y el firewall del panel de control de windows
* Deshabilitar extensiones del navegador de bloqueo de anuncios [FIXED OnVue frustrating technical network connection issue SOLVED](https://youtu.be/bzKBWbZ5NY4?si=-9GH82TmKLxJl7tI)
* Si el test de detecta que estas en una maquina virtual puedes ir al **regedit** de windows a cambiar unos valores
* si no funciona lo anterior entra a la BIOS de tu placa base y en las configuraciones de CPU deshabilita la virtualization de CPU
* Por ultimo elimina con el adiministrador de tareas las que aparezcan que estan corriendo

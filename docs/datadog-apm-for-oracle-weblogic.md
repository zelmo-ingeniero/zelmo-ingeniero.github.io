
# Immplement datadog APM into a default Oracle Weblogic site

Versions:
- OS: oracle 7.9
- JDK: /home/wl/jdk1.8
- Weblogic: 10.3.6
- datadog agent already installed

> Here the host type is VM

## Install and Configure JDK

Create weblogic user

```sh
groupadd wl
useradd -g wl wl
```

Extract jdk

```sh
tar zxf jdk-8u391-linux-x64.tar.gz
mv jdk1.8.0_391/ jdk1.8/
```

Edit the .bashrc file of the user wl

```sh
vi ~/.bashrc
```

Content:

```sh
export JAVA_HOME=/home/wl/jdk1.8
export PATH=$JAVA_HOME/bin:$PATH
```

Validate

```sh
java -version
```

## weblogic

Avoid GUI instalation with the next variable

```sh
export DISPLAY=:0
```

Run weblogic

```sh
java -jar wls1036_generic.jar
```

Export weblogic required variables

```sh
export ORACLE_BASE=/home/wl/oracle_home
export MW_HOME=$ORACLE_BASE/product/10.3.6
export WLS_HOME=$MW_HOME/wlserver
export WL_HOME=$WLS_HOME
export DOMAIN_BASE=$ORACLE_BASE/config/domains
export DOMAIN_HOME=$DOMAIN_BASE/adminDomain
```

## Apply datadog APM

### Download the dd-trace jar

Download the appropiate dd-trace library `.jar`

```sh
wget -O dd-java-agent.jar 'https://dtdg.co/latest-java-tracer'
```

- It should be located in the same path as the `setDomainEnv.sh` file
- The wl user should has read and execute permisions to this `.jar`

### Enable JMX in Weblogic

In the weblogic portal go to: Domain => Configuration => General => Advanced => And check the option "Platform MBean Server Enabled"

### Configure the datadog integration

Edit the `/etc/datadog-agent/conf.d/weblogic.d/conf.yaml` with your datadog service, host and port

```yaml
init_config:
    is_jmx: true
    collect_default_eetrics: true
    new_gc_metrics: true
    service: <your service>
instances:
  - host: localhost
    port: 9090

```

Add the next code at the end of the `SetDomainEnv.sh` file (are Java parameters readed by the dd-trace library)

- Change the parameters as you need, specially `-Ddd.env` and `-Ddd.tags`
- In my case each weblogic server runs with different JAVA_OPTIONS and then I need to use this conditions because i want to monitoring the  "Server-0" weblogic server

Lines:

```sh
if [ "$SERVER_NAME" = "AdminServer" ] ; then
        JAVA_OPTIONS="$JAVA_OPTIONS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9090 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djavax.management.builder.initial=weblogic.management.jmx.mbeanserver.WLSMBeanServerBuilder -Djava.rmi.server.hostname=127.0.0.1"
        export JAVA_OPTIONS
fi

if [ "$SERVER_NAME" = "Server-0" ] ; then
        JAVA_OPTIONS="$JAVA_OPTIONS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9191 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djavax.management.builder.initial=weblogic.management.jmx.mbeanserver.WLSMBeanServerBuilder -javaagent:/home/weblog/dd-java-agent.jar -Ddd.env=production -Ddd.tags=service:svcweblogic -Ddd.logs.injection=true -XX:FlightRecorderOptions=stackdepth=256 -Ddd.dbm.propagation.mode=full -Ddd.integration.jdbc-datasource.enabled=true -Djava.rmi.server.hostname=127.0.0.1"
        export JAVA_OPTIONS
fi
```

Run `StartWebLogic.sh`

Run `StarntNodeManager.sh`

restart de datadog agent

```sh
systemctl restart datadog-agent
```
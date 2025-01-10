
# Apply Datadog APM to Tomcat on Linux

Download the Java library as `.jar`

```bash
wget -O /opt/dd-java-agent.jar 'https://dtdg.co/latest-java-tracer'
```

The Java application's start should be modified by adding some new parameters to apply and configure the Datadog library tags

For example, if now the command to start the application is:

```bash
java -jar path/to/your/app.jar
```

Then with the Datadog instrumentation the command is:

```bash
java -javaagent:/opt/dd-java-agent.jar \
  -Ddd.logs.injection=true \
  -Ddd.trace.sample.rate=1 \
  -Ddd.dbm.propagation.mode=full \
  -XX:FlightRecorderOptions=stackdepth=256 \
  -Ddd.service=service_name \
  -Ddd.env=env_name \
  -Ddd.app=app_name \
  -Ddd.team=infra \
  -Ddd.version=1 \
  -jar path/to/your/app.jar
```

## Tomcat APM configuration 

At the end of the Tomcat file `setenv.sh` add this line

```bash
CATALINA_OPTS="$CATALINA_OPTS -javaagent:/opt/dd-java-agent.jar -Ddd.logs.injection=true -Ddd.trace.sample.rate=1 -Ddd.dbm.propagation.mode=service -XX:FlightRecorderOptions=stackdepth=256   -Ddd.service=myservice_name -Ddd.env=env_name -Ddd.app=app_name -Ddd.team=infra -Ddd.version=1"
```

> ![NOTE]
> Change the tag values for the corresponding to the environment

After the change, restart Tomcat and the Datadog agent. Datadog will collect APM traces from the Tomcat application

## Datadog Tomcat configuration 

In addition to APM traces, this Tomcat integration will collect more metricx and checks from Tomcat. Under the hood Datadog is monitoring JMX that is running Tomcat (for that reason is required to enable JMX on Tomcat)

Once JMX is enabled. Edit the Datadog configuration file for Tomcat, on Linux it is `/etc/datadog-agent/conf.d/tomcat.d/conf.yaml`

The content will be similar to:

```bash
init_config:
    is_jmx: true
    collect_default_metrics: true
    new_gc_metrics: true
instances:
  - host: localhost  
    port: <tomcat-jmx-port>
    user: <user>
    password: <password>
    tags:
      - team:infra
```

Save the file and restart the Datadog agent

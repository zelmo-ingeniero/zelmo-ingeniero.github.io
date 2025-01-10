
# Apply Datadog DBM to Oracle DB on Windows or Linux

## Prerequisites
- The Datadog agent is already installed
- The Oracle DB is already installed

Run in the DB the next queries to provide read permissions to the Datadog agent, see [SQL Queries to the DB](https://docs.datadoghq.com/integrations/oracle/?tab=windows)

## Create the configuration file in Windows

- Create a new empty file in `C:\ProgramData\Datadog\conf.d\sqlserver.d\` called `conf.yaml`
  - Keep in mind that the DB user's password must not have the `%` character
  - In this path  all `.yaml` files will be applied

In case of having an standalone DB the `conf.yaml` file would be like this:

```yaml
init_config:
instances:
  - dbm: true
    host: "<host-ip>,1433"
    database: master
    username: datadog
    password: ""
    connector: ado@api
    adoprovider: MSOLEDBSQL
    tags:
      - env:tag
      - app:tag
      - service:tag
```

- For starting, the `service`, `env` and `app` tags should match the `C:\ProgramData\Datadog\datadog.yaml` tags, anyways the tags can be changed in any moment
- In the Datadog agent manager or in the Windows Event Viewer restart the Datadog agent 
  - Afterwards, go to Status -> Collector in the Datadog Agent Manager, the oracle integration should appears with status OK

Some common problems are:
- Password with the `%` character
- The `conf.yaml` should change for the DB driver
- The `conf.yaml` should change for the DB version

## Create the configuration file in Linux

Edit or read the file `/etc/datadog-agent/datadog.yaml`

Copy the tags, for example:

```yaml
tags:
  - team:infra
  - env:prod
  - app:myapp
  - service:myservice
```

- Go to `conf.d/oracle.d/`
- Create a new file called `conf.yaml`

Content:

```yaml
instances:
- server: <server-ip>:1521
  service_name: <the-name-of-the-service-cdb>
  username: DATADOG
  password: <the-password>
  dbm: true
  tags:
    - env:prod
    - app:myapp
    - service:myservice
```

- Restart the datadog agent by running `systemctl restart datadog-agent` 
- Run `datadog-agent status` 
  - Check for the "oracle" integration it should be [OK]

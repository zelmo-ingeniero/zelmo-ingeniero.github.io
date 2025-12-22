


Connect to the Cloud SQL instance and then select your DB

```sql
SHOW DATABASES;
SELECT DATABASE();
USE my-db; 
```

Create table with the proper columns

```sql
CREATE TABLE `table_iso8583` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `0`   VARCHAR(4)   NULL,
  `3`   VARCHAR(6)   NULL,
  `4`   VARCHAR(12)  NULL,
  `7`   VARCHAR(10)  NULL,
  `11`  VARCHAR(6)   NULL,
  `12`  VARCHAR(6)   NULL,
  `13`  VARCHAR(4)   NULL,
  `15`  VARCHAR(4)   NULL,
  `17`  VARCHAR(4)   NULL,
  `18`  VARCHAR(4)   NULL,
  `22`  VARCHAR(3)   NULL,
  `25`  VARCHAR(2)   NULL,
  `32`  VARCHAR(11)  NULL,
  `35`  VARCHAR(37)  NULL,
  `37`  VARCHAR(12)  NULL,
  `38`  VARCHAR(6)   NULL,
  `39`  VARCHAR(2)   NULL,
  `41`  VARCHAR(16)  NULL,
  `42`  VARCHAR(15)  NULL,
  `43`  VARCHAR(40)  NULL,
  `44`  VARCHAR(4)   NULL,
  `45`  VARCHAR(76)  NULL,
  `48`  VARCHAR(30)  NULL,
  `49`  VARCHAR(3)   NULL,
  `54`  VARCHAR(30)  NULL,
  `57`  VARCHAR(2004) NULL,
  `60`  VARCHAR(19)  NULL,
  `61`  VARCHAR(22)  NULL,
  `62`  VARCHAR(13)  NULL,
  `63`  VARCHAR(1000) NULL,
  `70`  VARCHAR(3)   NULL,
  `90`  VARCHAR(42)  NULL,
  `95`  VARCHAR(42)  NULL,
  `100` VARCHAR(11)  NULL,
  `102` VARCHAR(28)  NULL,
  `110` VARCHAR(103) NULL,
  `120` VARCHAR(32)  NULL,
  `121` VARCHAR(23)  NULL,
  `122` VARCHAR(14)  NULL,
  `123` VARCHAR(23)  NULL,
  `125` VARCHAR(15)  NULL,
  `126` VARCHAR(41)  NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

Chack the columns

```sql
select * from table_iso8583;
```

Get ready the command to insert rows to the table (this will be used by the Dataflow, that means the "?" symbols)

```sql
INSERT INTO `table_iso8583` ( `0`,`3`,`4`,`7`,`11`,`12`,`13`,`15`,`17`,`18`,`22`,`25`, `32`,`35`,`37`,`38`,`39`,`41`,`42`,`48`,`49`,`54`,`57`, `60`,`61`,`63`,`100`,`120`,`121`,`125`) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
```

Create Dataflow using the template "Pubsub_to_Jdbc". The parameters are separaed by the "~" symbol because the parameters contains "," and "."

```bash
gcloud dataflow flex-template run "dataflow-sql-$(date +%Y%m%d-%H%M)"   --region northamerica-south1   --template-file-gcs-location gs://dataflow-templates-northamerica-south1/2025-08-05-00_RC01/flex/Pubsub_to_Jdbc   --enable-streaming-engine   --staging-location gs://my-bucket/staging   --parameters='^~^inputSubscription=projects/my-project/subscriptions/my-subscription~outputDeadletterTopic=projects/my-project/subscriptions/my-subscription-dataflow-dlq~driverClassName=com.mysql.cj.jdbc.Driver~driverJars=gs://my-bucket/jars/mysql-connector-j-8.4.0.jar,gs://my-bucket/jars/mysql-socket-factory-connector-j-8-1.15.0.jar,gs://my-bucket/jars/jdbc-socket-factory-core-1.15.0.jar,gs://my-bucket/jars/jnr-constants-0.10.4.jar,gs://my-bucket/jars/jnr-enxio-0.32.16.jar,gs://my-bucket/jars/jnr-ffi-2.2.15.jar,gs://my-bucket/jars/jnr-posix-3.1.18.jar,gs://my-bucket/jars/jnr-unixsocket-0.38.21.jar,gs://my-bucket/jars/google-api-client-2.2.0.jar,gs://my-bucket/jars/google-api-services-sqladmin-v1beta4-rev20231108-2.0.0.jar,gs://my-bucket/jars/google-auth-library-credentials-1.20.0.jar,gs://my-bucket/jars/google-auth-library-oauth2-http-1.20.0.jar,gs://my-bucket/jars/google-http-client-1.43.3.jar,gs://my-bucket/jars/google-http-client-gson-1.43.3.jar,gs://my-bucket/jars/google-http-client-jackson2-1.43.3.jar,gs://my-bucket/jars/google-oauth-client-1.34.1.jar~connectionUrl=jdbc:mysql://google/my-db?cloudSqlInstance=my-project:northamerica-south1:my-cloudsql-instance&socketFactory=com.google.cloud.sql.mysql.SocketFactory&useSSL=false&ipTypes=PUBLIC~username=my-db-user~password=changeit~connectionProperties=rewriteBatchedStatements=true~statement=INSERT INTO `table_iso8583` ( `0`,`3`,`4`,`7`,`11`,`12`,`13`,`15`,`17`,`18`,`22`,`25`, `32`,`35`,`37`,`38`,`39`,`41`,`42`,`48`,`49`,`54`,`57`, `60`,`61`,`63`,`100`,`120`,`121`,`125`) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
```

Test by sending messages to the pubsub like this:

```bash
gcloud pubsub topics publish my-topic --message='{`0`:"0210",`3`:"002100",`4`:"000000000000",`7`:"0825205224",`11`:"511014",`12`:"205224",`13`:"0825",`15`:"4816",`17`:"4816",`18`:"4816",`22`:"101",`25`:"59",`32`:"12345678912",`35`:"1234567891234567891234567891234567891",`37`:"123456789123",`38`:"123456",`39`:"12",`41`:"70daca4f-0151-4f",`42`:"8098225        ",`48`:"080",`49`:"982",`54`:"            0001255209848",`57`:"1627535******0240=****021627535******0240=****019B072PAYW-3600001-is022B114    00000000000098132& 0000500132! C000026 XXX  001     053487  1 0  ! Q200002 09! C400012 102510003660! CH00040   000000000000             000          11900000001140321234567891234567891234567891234502312345678909876543212345015P6HOSTB24 0 876",`60`: "",`61`: "",`63`: "",`100`: "",`120`: "",`121`: "",`125`: ""}'
```


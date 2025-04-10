# Store AWS Redshift data in a local file and how to use it

This journey is about run the `UNLOAD` command in one table from an old Redshift Database and then using `COPY` to fill a different Redshift Database table, even in a different AWS acccount! This enable the deletion of old Redshift instances

**Basically this are the steps**:

1. Create and EC2 instance in the AWS account with the old Redshift, that instance will connect with the Redshift and perform the `UNLOAD` command to extract the data from the database and store it in an S3 bucket.
2. Then download the CSV file generared by the `UNLOAD` locally
3. In another AWS account upload the CSV to some S3 bucket
4. Finally use the `COPY` command to store the data from the file to the new Redshift database

Prerequisites:

- Both Redshift instances should have the appropiate IAM permissions to the correspondingsssS3 bucket and the EC2 instance that will be used
- The new Redshift instance must have existing the empty tables from the old database
- The `UNLOAD` and `COPY` commands interact with S3 buckets so ensure to add IAM permissions to the Redshift and EC2 instances

Install this drivers and Python

```bash
dnf update
dnf install -y unixODBC unixODBC-devel
dnf install -y python3 python3-pip
```

Download and install the next RPM for Redshift

```bash
wget https://s3.amazonaws.com/redshift-downloads/drivers/odbc/1.5.20.1024/AmazonRedshiftODBC-64-bit-1.5.20.1024-1.x86_64.rpm
dnf -y localinstall AmazonRedshiftODBC-64-bit-1.5.20.1024-1.x86_64.rpm
```

In some directory, initiate the python project

```bash
python3 -m venv env
source env/bin/activate
pip install --target=$(pwd) pyodbc
```

Edit this driver configuration file

```bash
vi /etc/odbc.ini
```

Add this content (`/opt/amazon/redshiftodbcx64/librsodbc64.so` appears from the Redshift driver installation)

```ini
[Amazon Redshift (x64)]
Description=Amazon Redshift ODBC Driver
Driver=/opt/amazon/redshiftodbcx64/librsodbc64.so
```

Edit this driver configuration file

```bash
vi /etc/odbcinst.ini
```

Add this content

```ini
[Amazon Redshift (x64)]
Description     = ODBC for Redshift
Driver          = /opt/amazon/redshiftodbc/lib/64/libamazonredshiftodbc64.so
```

Validate by running (the output should show `[Amazon Redshift (x64)]`)

```bash
odbcinst -q -d
odbcinst -q -s
```

Then create this Python file

```bash
vi my-code.py
```

This code connects with the Redshift through `pyodbc`

- The first query show in the terminal output the first 10 rows from the dessired table (in this case is `"public.tbl_transactions_h"`), this is just to verify the content
- The second and third query are to show in the terminal how to create the same table with the same columns in the next Redshift instance, copy that SQL code and create the empty tables in the new Redshift
- The fourth query is to count how many rows has the table
- The fifth query is to run the `UNLOAD` command to extract the data from the old Redshift and store it as a file in an S3 bucket (remember to replace the values between `<>`)

```python
import pyodbc
print(pyodbc.drivers())

server = "<Redshift ODBC conection string>"
database = "dev"
user = "admin"
password = "<the super secure password>"
port = 5439

conn_str = 'Driver={Amazon Redshift (x64)}; Server=${server}; Database=dev; Uid=admin; Pwd=${password};  Port=5439'
conn = None
try:
    print(conn_str)
    conn = pyodbc.connect(conn_str)
    print(conn)
    cursor = conn.cursor()

    cursor.execute("SELECT t.* FROM public.tbl_transactions_h t LIMIT 10;")
    rows = cursor.fetchall()
    print(rows)

    print("000000000000000000000")
    print("second query")
    print("000000000000000000000")
    cursor.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'tbl_transactions_h' ORDER BY ordinal_position;")
    rows = cursor.fetchall()
    for row in rows:
        print(row)

    print("000000000000000000000")
    print("third query")
    print("000000000000000000000")
    cursor.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'tbl_transactions_log' ORDER BY ordinal_position;")
    rows = cursor.fetchall()
    for row in rows:
        print(row)

    print("000000000000000000000")
    print("fourth query")
    print("000000000000000000000")
    cursor.execute("SELECT COUNT(*) FROM public.tbl_transactions_h t;")
    rows = cursor.fetchall()
    for row in rows:
        print(row)

    print("000000000000000000000")
    print("fifth query")
    print("000000000000000000000")
    cursor.execute("UNLOAD ('SELECT * FROM tbl_transactions_h') TO 's3://<THE BUCKET NAME>/<THE TABLE NAME>' IAM_ROLE '<AN IAM ROLE WITH REDSHIFT AND S3 PERMISSIONS>' DELIMITER ',' ADDQUOTES ALLOWOVERWRITE PARALLEL OFF;")
    rows = cursor.fetchall()
    for row in rows:
        print(row)

except pyodbc.Error as ex:
    sqlstate = ex.args[0]
    print(ex)
finally:
    print("cerrando")
    if conn:
        conn.close()
print("finalizado")

```

Run the python code

```bash
python3 codigo.py
```

Review if the file was created in the S3 bucket 

>![NOTE]
> This can create many files, each one of a big size

Download all of the files and uploadit in a different AWS account

### How to import the data to the new Redshift database

Once the CSV data is uploaded in the S3 bucket in a different account follow this steps:

- Create a new Redshift instance and ensure to create an IAM role that enable comunication between the bucket and the Redshift database
- Ensure that the new Redshift database has existing the empty tables, if not then is necessary to create them with SQL code

```sql
CREATE TABLE public.tbl_transactions_h (
    message character varying,
    card character varying,
    entry_mode character varying,
    procesing_code character varying,
    pos_data character varying,
    terminal_id character varying,
    mcc character varying,
    merchant_id character varying,
    merchant_description character varying,
    retrieval_number character varying,
    trace_number character varying,
    tx_time character varying,
    tx_date character varying,
    tx_date_time character varying,
    merchant_amount numeric,
    compensation_amount numeric,
    settlement_amount numeric,
    merchant_currency character varying,
    compensation_currency character varying,
    settlement_currency character varying,
    exchange_rate numeric,
    mc_code character varying,
    system_timestamp timestamp without time zone,
    entry_date timestamp without time zone,
    bin character varying,
    last4digits character varying
);

CREATE TABLE public.tbl_transactions_log (
    id integer,
    counter integer,
    message character varying,
    card character varying,
    entry_mode character varying,
    procesing_code character varying,
    terminal_id character varying,
    mcc character varying,
    merchant_id character varying,
    merchant_description character varying,
    retrieval_number character varying,
    trace_number character varying,
    tx_time character varying,
    tx_date character varying,
    amount numeric,
    response_code character varying,
    description character varying,
    vip integer,
    system_timestamp timestamp without time zone,
    entry_date timestamp without time zone,
    bin character varying,
    last4digits character varying
);
```

Make sure that the columns of the new tables have the same order than the old tables

```sql
SELECT * FROM tbl_transactions_h;
SELECT * FROM tbl_transactions_log;
```

Run this SQL code in the new database

```sql
COPY tbl_transactions_h 
FROM 's3://<THE S3 BUCKET NAME>/<THE FILE IN THE S3>' 
CREDENTIALS '<THE IAM ROLE>' 
FORMAT AS CSV;

COPY tbl_transactions_h FROM 's3://<THE S3 BUCKET NAME>/<THE SECOND FILE IN THE S3>' 
CREDENTIALS '<THE IAM ROLE>' FORMAT AS CSV;
```

Then the data is already in the new Redshift database!
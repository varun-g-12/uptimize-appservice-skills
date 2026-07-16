# Introduction to AppService Databases

A Databases module (sometimes goes by name DBaaS), is a module, that implements
capability of persistent storage for applications built with UPTIMIZE AppService.
It is being implemented as a separate AppService account to ensure high level
of isolation from primary AWS account, and built with data isolation in mind.
It is based on PostgreSQL Database Engine, which is a core for whole system.

This module:
- gives an ability to create databases easily, in one click, without need to
  handle complex technical details of starting up a database on AWS
- grants capability for data storage, easy to connect to
  database, whenever it is needed, with as much application as it is needed
- allow easy access and injestion of data through ability to connect to the
  database via direct connection within Merck network

Non-goals of module:
- build a big data storage and processing system
- build a storage, capable of handling high volumes of incoming traffic

---

# How to use AppService Databases

This document explains, how to use AppService Databases module for end users.
It is covering few major parts of usage of the system: create database, connect
to it using Merck computer, and connect an application to the database. First,
we will start with high level explanation of what is happening, and then go on
with specific examples with code examples on how to use it.

## High level ideas

*AppService Databases* uses the AWS capabilities to all they can bring us in
order to ensure capabilities. The database management is implemented through
CloudFormation mechanism, to ensure ability to roll back and ensure follow on
in changes. The authentication to databases is implemented through IAM
capabilities, which ensures ability to keep ability to connect to specific
databases in a safe manner by generating short term tokens.

So, essentially first when you want to use the database, you need to create
one. This is done through AppService Management Console "Databases" tab. If
you don't have one, please contact the administrator of the system so they can
grant the access to it to you.

Then, in order to connect to the database, we need to generate one-time tokens
in order to connect to it. The same kind of token is going to be used both for
personal connectivity, and for application connectivity, but the way we will be
getting one will differ (see how to do it in the next example). The only
important thing is that the _connectivity token will always be valid for 15
minutes_. This should not pose a problem for applications, as those usually
keep a long-living connection to the database (except for few exceptions, like
Django ORM, which will be covered too), while allowing to safeguard connection
using personal credentials.

## How to create a database

The process of creation a database is extremely simple: all you need to do is
to navigate to the "Databases" tab in Factory Management Console, and click
"Create Database" button, as it is highlighted on a screenshot. You will need
to wait for up to 30 seconds in order for changes to be applied, and a new
database will appear. If it does not, try refreshing the page.  If it does not
help after few attempts,  or you see "FAILED" in status column, please contact
system administrator.

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-create-db-highlight.png)

The name of database is generated at random, but always start with `db_`
prefix.

Note: As of the moment the document is being written, the only databases you
will be able to see, are databases that you created.

## How to connect to a database from Merck computer

After you created a database, you might want to connect to it directly to
upload the data. In order to do that, you will need to press the "Get
Credentials" button on a database you'd like to connect to , as it is
highlighted on a screenshot. It will generate a personal connectivity token to
the database. *Note: it is going to be valid for 15 minutes*

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-get-credentials.png)

Then, after a brief time to wait for correct accesses to be created, the next
popup will be presented, with all data you will need to connect. You can use
same credentials both to connect to the database directly via `psql` or DBeaver
client, or use it to connect a locally running database, as long as you are
using Merck computer or are connected to the VPN.

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-credentials.png)

## How to connect an application on AppService

Whenever you want to connect an actual application to the database, you need to
execute few steps first:
1. grant an application access to the database
2. fetch connectivity token on database
3. connect to the database

### Granting access to application

In order to grant an application an access to database, first you need to open
"Details" view of a database by clicking on it's name.

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-db-details-placement.png)

Then, click "Connect Application":

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-db-details-connect.png)

After it, choose your application in a dialog box, and click "Connect".

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-connect-app.png)

In brief moment (about 15-30 seconds), it should appear in the table after
refresh.

### Generating connectivity token in application

In order to connect to the database within application, first you will need to
generate a short-term connectivity token. In order to do that, you will need
these things prepared first:
- install an AWS library within your application (e.g. `boto3` for Python, or
  `aws-sdk` for node.js)
- install a PostgreSQL driver in order to connect to the database (e.g. for
  Python, it is `psycopg2-binary`, or `node-postgres` for node.js)
- get the information you can find in the "Applications" table on the line
  that corresponds to specific application you connect, as you can see on a
  screenshot: the UserName and the IAM Role.

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-db-details-conn-details.png)

Then, there are few steps you will need to execute in order to generate the
token. The example here is in Python, although it is going to look mostly the
same in any of languages that have an official AWS SDK and a PostgreSQL
connector:

```python
import boto3

host = ...     # Use hostname in the top block
port = 5432    # Default port, though check it on the database page
iam_role = ... # Here you put the IAM Role from the table
user = ...     # Here you put a User Name from the table
database = ... # Name of a database, e.g. "db_asdfASDF'

# Note: this should have this specific value
# The value should be common, because AWS operates in eu-central region
# If this value is incorrect, you won't be able to connect to the database
region = 'eu-central-1'

# Because the AppService Databases is located in a separate account,
# we need to first assume role to gain possibility to generate a correct
# token.
sts = boto3.client(
    'sts', endpoint_url='https://sts.eu-central-1.amazonaws.com')
credentials = sts.assume_role(
    RoleArn=iam_role,
    RoleSessionName='connectivityTest1',
)['Credentials']

# Then, we need to initialize the AWS RDS client with credentials
# in the Databases AWS account
rds = boto3.client(
    'rds',
    aws_access_key_id=credentials['AccessKeyId'],
    aws_secret_access_key=credentials['SecretAccessKey'],
    aws_session_token=credentials['SessionToken'],
)

# Then we generate token
token = rds.generate_db_auth_token(
    DBHostname=host,
    Port=port,
    DBUsername=user,
    Region=region,
)
```

### Connecting to the database

Connecting to specific applications might vary from tools you are going to use,
but, commonly, the only thing you need to do is pass the `token` we generated
in the previous section into the `password` field, like this (if you are using
raw connector:

```python
import psycopg2 as pg

with pg.connect(host=host, port=port, user=user, password=token, dbname=database) as conn:
    with conn.cursor() as cursor:
        cursor.execute('SELECT NOW();')
        result = cursor.fetchall()
        print(result)
```

Although, the same limitation is being imposed as it is on the personal token
to connect to the database from user machine directly: the token is valid for
15 minutes since creation, and after the time passes, it will stop being valid.
This introduces complications to applications, which do not keep connection
alive for long timeframes, like Django. You will need to specific workaround
for specific tool you are going to be using, like this solution for Django
framework:
[link](https://stackoverflow.com/questions/57865837/how-to-do-rds-iam-authentication-with-django).

# Important notes on database usage

We are using the top-notch storage solution that AWS provides, which gives
extreme scalability capabilities. Yet still it has it's own limitations, so
there is a need to keep some things in mind in order to make usage of the
system as smooth as it is possible:
- There are daily backups of the database overall, so it is possible to restore
  data overall. Although, the process is complex and requires administrator
  help, so if it is possible: try not to remove data, but copy it to another
  table to ensure it's safety.
- Sometimes, it is better to write simpler queries and perform filtering or
  operations on the application layer, as it will can make result calculation
  much faster. Especially if there is some complex logic.

Thanks a lot for reading up to this point, I hope you found this document
useful. Good luck using AppService Databases. :)

---

# Administrator Guide on AppService Databases

This document will explain most common issues and how to deal with those.

## How to grant user capability to use Databases module

In order to grant user capability to use Databases module, you will need to
change the variable `REACT_APP_FEATURE_FLAG_ADMINS` in [management-console env](https://dev.azure.com/Uptimize/factory-appservice-nreg-ec1/_git/factory-appservice-nreg-ec1?path=/management-console/frontend/.env).

You need to append a Merck account name (e.g. anthony.stark@merckgroup.com) to
the variable in the end of line, by prepending a comma before it so it looks
like a comma-separated list. After that, a new version Uptimize App Service
Management Console has to be deployed.

## Debugging FAILED status when creating database

In order to debug the problem, you will need to go open CloudFormation section
in AWS in corresponding account of AppService, then look for failed jobs.
There, in logs should be information on what's gone wrong.

If there is not, then you will need to check logs inside of
`ec1-da-<x>-processpharmx-nreg-\*` logs for Service Broker lambda. This should
give better understanding on the underlying issue.

## Restoring database data in case of failure

The DBaaS is having daily backups being made each day. You should be able to
restore specific data doing a restore from backup.

How to do it:
1. Log in into corresponding DBaaS account
2. Go to RDS, then to Databases
3. Choose `ec1-rds-aurora`
4. On top right corner choose `Actions -> Restore to point in time`
5. The dialog of database creation will open, make sure you fill all required
   params
6. Connect to it from Merck machine using root credentials from SecretsManager
7. Dump all the data you might need from that database
# How to use AppService Databases

This document explains, how to use AppService Databases module for end users.
It is covering few major parts of usage of the system: create database, connect
to it using Merck computer, and connect an application to the database. First,
we will start with high level explanation of what is happening, and then go on
with specific examples with code examples on how to use it.

## High level ideas

*AppService Databases* uses the AWS capabilities to all they can bring us in
order to ensure capabilities. The database management is implemented through
CloudFormation mechanism, to ensure ability to roll back and ensure follow on
in changes. The authentication to databases is implemented through IAM
capabilities, which ensures ability to keep ability to connect to specific
databases in a safe manner by generating short term tokens.

So, essentially first when you want to use the database, you need to create
one. This is done through AppService Management Console "Databases" tab. If
you don't have one, please contact the administrator of the system so they can
grant the access to it to you.

Then, in order to connect to the database, we need to generate one-time tokens
in order to connect to it. The same kind of token is going to be used both for
personal connectivity, and for application connectivity, but the way we will be
getting one will differ (see how to do it in the next example). The only
important thing is that the _connectivity token will always be valid for 15
minutes_. This should not pose a problem for applications, as those usually
keep a long-living connection to the database (except for few exceptions, like
Django ORM, which will be covered too), while allowing to safeguard connection
using personal credentials.

## How to create a database

The process of creation a database is extremely simple: all you need to do is
to navigate to the "Databases" tab in Factory Management Console, and click
"Create Database" button, as it is highlighted on a screenshot. You will need
to wait for up to 30 seconds in order for changes to be applied, and a new
database will appear. If it does not, try refreshing the page.  If it does not
help after few attempts,  or you see "FAILED" in status column, please contact
system administrator.

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-create-db-highlight.png)

The name of database is generated at random, but always start with `db_`
prefix.

Note: As of the moment the document is being written, the only databases you
will be able to see, are databases that you created.

## How to connect to a database from Merck computer

After you created a database, you might want to connect to it directly to
upload the data. In order to do that, you will need to press the "Get
Credentials" button on a database you'd like to connect to , as it is
highlighted on a screenshot. It will generate a personal connectivity token to
the database. *Note: it is going to be valid for 15 minutes*

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-get-credentials.png)

Then, after a brief time to wait for correct accesses to be created, the next
popup will be presented, with all data you will need to connect. You can use
same credentials both to connect to the database directly via `psql` or DBeaver
client, or use it to connect a locally running database, as long as you are
using Merck computer or are connected to the VPN.

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-credentials.png)

## How to connect an application on AppService

Whenever you want to connect an actual application to the database, you need to
execute few steps first:
1. grant an application access to the database
2. fetch connectivity token on database
3. connect to the database

### Granting access to application

In order to grant an application an access to database, first you need to open
"Details" view of a database by clicking on it's name.

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-db-details-placement.png)

Then, click "Connect Application":

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-db-details-connect.png)

After it, choose your application in a dialog box, and click "Connect".

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-connect-app.png)

In brief moment (about 15-30 seconds), it should appear in the table after
refresh.

### Generating connectivity token in application

In order to connect to the database within application, first you will need to
generate a short-term connectivity token. In order to do that, you will need
these things prepared first:
- install an AWS library within your application (e.g. `boto3` for Python, or
  `aws-sdk` for node.js)
- install a PostgreSQL driver in order to connect to the database (e.g. for
  Python, it is `psycopg2-binary`, or `node-postgres` for node.js)
- get the information you can find in the "Applications" table on the line
  that corresponds to specific application you connect, as you can see on a
  screenshot: the UserName and the IAM Role.

![Create Database Placement](https://docs.uptimize.merckgroup.com/assets/appservice/appservice-dbaas-db-details-conn-details.png)

Then, there are few steps you will need to execute in order to generate the
token. The example here is in Python, although it is going to look mostly the
same in any of languages that have an official AWS SDK and a PostgreSQL
connector:

```python
import boto3

host = ...     # Use hostname in the top block
port = 5432    # Default port, though check it on the database page
iam_role = ... # Here you put the IAM Role from the table
user = ...     # Here you put a User Name from the table
database = ... # Name of a database, e.g. "db_asdfASDF'

# Note: this should have this specific value
# The value should be common, because AWS operates in eu-central region
# If this value is incorrect, you won't be able to connect to the database
region = 'eu-central-1'

# Because the AppService Databases is located in a separate account,
# we need to first assume role to gain possibility to generate a correct
# token.
sts = boto3.client(
    'sts', endpoint_url='https://sts.eu-central-1.amazonaws.com')
credentials = sts.assume_role(
    RoleArn=iam_role,
    RoleSessionName='connectivityTest1',
)['Credentials']

# Then, we need to initialize the AWS RDS client with credentials
# in the Databases AWS account
rds = boto3.client(
    'rds',
    aws_access_key_id=credentials['AccessKeyId'],
    aws_secret_access_key=credentials['SecretAccessKey'],
    aws_session_token=credentials['SessionToken'],
)

# Then we generate token
token = rds.generate_db_auth_token(
    DBHostname=host,
    Port=port,
    DBUsername=user,
    Region=region,
)
```

### Connecting to the database

Connecting to specific applications might vary from tools you are going to use,
but, commonly, the only thing you need to do is pass the `token` we generated
in the previous section into the `password` field, like this (if you are using
raw connector:

```python
import psycopg2 as pg

with pg.connect(host=host, port=port, user=user, password=token, dbname=database) as conn:
    with conn.cursor() as cursor:
        cursor.execute('SELECT NOW();')
        result = cursor.fetchall()
        print(result)
```

Although, the same limitation is being imposed as it is on the personal token
to connect to the database from user machine directly: the token is valid for
15 minutes since creation, and after the time passes, it will stop being valid.
This introduces complications to applications, which do not keep connection
alive for long timeframes, like Django. You will need to specific workaround
for specific tool you are going to be using, like this solution for Django
framework:
[link](https://stackoverflow.com/questions/57865837/how-to-do-rds-iam-authentication-with-django).

# Important notes on database usage

We are using the top-notch storage solution that AWS provides, which gives
extreme scalability capabilities. Yet still it has it's own limitations, so
there is a need to keep some things in mind in order to make usage of the
system as smooth as it is possible:
- There are daily backups of the database overall, so it is possible to restore
  data overall. Although, the process is complex and requires administrator
  help, so if it is possible: try not to remove data, but copy it to another
  table to ensure it's safety.
- Sometimes, it is better to write simpler queries and perform filtering or
  operations on the application layer, as it will can make result calculation
  much faster. Especially if there is some complex logic.

Thanks a lot for reading up to this point, I hope you found this document
useful. Good luck using AppService Databases. :)
# Administrator Guide on AppService Databases

This document will explain most common issues and how to deal with those.

## How to grant user capability to use Databases module

In order to grant user capability to use Databases module, you will need to
change the variable `REACT_APP_FEATURE_FLAG_ADMINS` in [management-console env](https://dev.azure.com/Uptimize/factory-appservice-nreg-ec1/_git/factory-appservice-nreg-ec1?path=/management-console/frontend/.env).

You need to append a Merck account name (e.g. anthony.stark@merckgroup.com) to
the variable in the end of line, by prepending a comma before it so it looks
like a comma-separated list. After that, a new version Uptimize App Service
Management Console has to be deployed.

## Debugging FAILED status when creating database

In order to debug the problem, you will need to go open CloudFormation section
in AWS in corresponding account of AppService, then look for failed jobs.
There, in logs should be information on what's gone wrong.

If there is not, then you will need to check logs inside of
`ec1-da-<x>-processpharmx-nreg-\*` logs for Service Broker lambda. This should
give better understanding on the underlying issue.

## Restoring database data in case of failure

The DBaaS is having daily backups being made each day. You should be able to
restore specific data doing a restore from backup.

How to do it:
1. Log in into corresponding DBaaS account
2. Go to RDS, then to Databases
3. Choose `ec1-rds-aurora`
4. On top right corner choose `Actions -> Restore to point in time`
5. The dialog of database creation will open, make sure you fill all required
   params
6. Connect to it from Merck machine using root credentials from SecretsManager
7. Dump all the data you might need from that database
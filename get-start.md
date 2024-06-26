
# 環境設定
ターミナルで以下のコマンドを実行して、Docker Composeファイルをダウンロードします。
```
curl -LfO 'https://airflow.apache.org/docs/apache-airflow/2.9.0/docker-compose.yaml'
```

![](pic/2024-05-08-08-28-19.png)


docker-compose.yamlファイルを開き、以下の行を追加します。
```
  volumes:
    - ./dags:/opt/airflow/dags
    - ./logs:/opt/airflow/logs
    - ./plugins:/opt/airflow/plugins
    - ./dbt:/dbt # add this in
    - ./dags:/dags # add this in
```

.envファイルを作成し、以下の行を追加します。
```
_PIP_ADDITIONAL_REQUIREMENTS=dbt-snowflake==1.7.3
dbt_account=xxxxx
dbt_user=xxxxx
dbt_password=xxxxx
dbt_database=xxxx_DB
dbt_warehouse=xxxxx_WH
dbt_schema=AIRFLOW_DBT
```

```
brew update
brew tap dbt-labs/dbt
```


dbtが導入されているかどうかを確認するために、以下のコマンドを実行します。
```
dbt --version
```

以下のエラーが表示された場合、dbtがインストールされていないことを示しています。
```
zsh: command not found: dbt
```

以下のコマンドを実行して、dbtをインストールします。
```
# brew install dbt
brew update
brew install git
brew tap dbt-labs/dbt
brew install dbt-snowflake

# pip install dbt
python3 -m pip install dbt-core dbt-snowflake
```

dbtが正常にインストールされたかどうかを確認するために、以下のコマンドを実行します。
```
dbt init dbt_sf
```

ユーザ名、パスワード、ロール、ウェアハウス、データベース、スキーマを入力します。
```
23:57:11  Running with dbt=1.7.14
23:57:11  
Your new dbt project "dbt_sf" was created!

For more information on how to configure the profiles.yml file,
please consult the dbt documentation here:

  https://docs.getdbt.com/docs/configure-your-profile

One more thing:

Need help? Don't hesitate to reach out to us via GitHub issues or on Slack:

  https://community.getdbt.com/

Happy modeling!

23:57:11  Setting up your profile.
Which database would you like to use?
[1] snowflake

(Don't see the one you want? https://docs.getdbt.com/docs/available-adapters)

Enter a number: 1
account (https://<this_value>.snowflakecomputing.com): xxxx
user (dev username): xxxx@company.com
[1] password
[2] keypair
[3] sso
Desired authentication type option (enter a number): 1
password (dev password): 
role (dev role): SYSADMIN
warehouse (warehouse name): xxxx_WH
database (default database that dbt will build objects in): xxxx_DB
schema (default schema that dbt will build objects in): AIRFLOW_DBT
threads (1 or more) [1]: 1
23:59:58  Profile dbt_sf written to /Users/xxxx/.dbt/profiles.yml using target's profile_template.yml and your supplied values. Run 'dbt debug' to validate the connection.
```

```
mkdir dags
```
ツリーレポジトリは以下のようになります。

![](pic/2024-05-08-09-13-24.png)



# DBTプロジェクトの設定

ブラウザからsnowflakeにアクセスし、以下のクエリを実行します。
```
user role SYSADMIN;
use database xxxx_DB;
create schema AIRFLOW_DBT;
```

スキーマが作成されたことが確認できます。
![](pic/2024-05-08-09-10-14.png)


ローカルで以下のコマンドを実行して、DBTプロジェクトを作成します。


```
cd dbt_sf
vi profiles.yml
vi packages.yml
vi dbt_project.yml
vi macros/custom_demo_macros.sql
```

```profiles.yml
default:
  target: dev
  outputs:
    dev:
      type: snowflake
      ######## Please replace with your Snowflake account name 
      ######## for example sg_demo.ap-southeast-1
      account: "{{ env_var('dbt_account') }}"

      user: "{{ env_var('dbt_user') }}"
      ######## These environment variables dbt_user and dbt_password 
      ######## are read from the variabls in Airflow which we will set later
      password: "{{ env_var('dbt_password') }}"

      role: SYSADMIN
      database: "{{ env_var('dbt_database') }}"
      warehouse: "{{ env_var('dbt_warehouse') }}"
      schema: "{{ env_var('dbt_schema') }}"
      threads: 200
```


```packages.yml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1
```


```dbt_project.yml
name: example
profile: default
models:
  my_new_project:
      # Applies to all files under models/example/
      transform:
          schema: transform
          materialized: view
      analysis:
          schema: analysis
          materialized: view
seed-paths: ["data"]    
```

```custom_demo_macros.sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}


{% macro set_query_tag() -%}
  {% set new_query_tag = model.name %} {# always use model name #}
  {% if new_query_tag %}
    {% set original_query_tag = get_current_query_tag() %}
    {{ log("Setting query_tag to '" ~ new_query_tag ~ "'. Will reset to '" ~ original_query_tag ~ "' after materialization.") }}
    {% do run_query("alter session set query_tag = '{}'".format(new_query_tag)) %}
    {{ return(original_query_tag)}}
  {% endif %}
  {{ return(none)}}
{% endmacro %}
```


ツリーレポジトリは以下のようになります。
![](pic/2024-05-08-09-41-11.png)

# dbtでのCSVデータファイルの作成

csvを作成します。
```bookings_1.csv
id,booking_reference,hotel,booking_date,cost
1,232323231,Pan Pacific,2021-03-19,100
1,232323232,Fullerton,2021-03-20,200
1,232323233,Fullerton,2021-04-20,300
1,232323234,Jackson Square,2021-03-21,400
1,232323235,Mayflower,2021-06-20,500
1,232323236,Suncity,2021-03-19,600
1,232323237,Fullerton,2021-08-20,700
```

```bookings_2.csv
id,booking_reference,hotel,booking_date,cost
2,332323231,Fullerton,2021-03-19,100
2,332323232,Jackson Square,2021-03-20,300
2,332323233,Suncity,2021-03-20,300
2,332323234,Jackson Square,2021-03-21,300
2,332323235,Fullerton,2021-06-20,300
2,332323236,Suncity,2021-03-19,300
2,332323237,Berkly,2021-05-20,200
```

```customers.csv
id,first_name,last_name,birthdate,membership_no
1,jim,jone,1989-03-19,12334
2,adrian,lee,1990-03-10,12323
```

![](pic/2024-05-08-09-51-00.png)


# modelsフォルダへのdbtモデルの作成

```
mkdir models/analysis
mkdir models/transform
vi models/analysis/hotel_count_by_day.sql
vi models/analysis/thirty_day_avg_cost.sql
vi models/transform/combined_bookings.sql
vi models/transform/customer.sql
vi models/transform/prepped_data.sql
```



```combined_bookings.sql
{{ dbt_utils.union_relations(
    relations=[ref('bookings_1'), ref('bookings_2')]
) }}
```

```customer.sql
SELECT ID 
    , FIRST_NAME
    , LAST_NAME
    , birthdate
FROM {{ ref('customers') }}
```


```prepped_data.sql
SELECT A.ID 
    , FIRST_NAME
    , LAST_NAME
    , birthdate
    , BOOKING_REFERENCE
    , HOTEL
    , BOOKING_DATE
    , COST
FROM {{ref('customer')}}  A
JOIN {{ref('combined_bookings')}} B
on A.ID = B.ID
```


```hotel_count_by_day.sql
SELECT
  BOOKING_DATE,
  HOTEL,
  COUNT(ID) as count_bookings
FROM {{ ref('prepped_data') }}
GROUP BY
  BOOKING_DATE,
  HOTEL
```


```thirty_day_avg_cost.sql
SELECT
  BOOKING_DATE,
  HOTEL,
  COST,
  AVG(COST) OVER (
    ORDER BY BOOKING_DATE ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ) as "30_DAY_AVG_COST",
  COST -   AVG(COST) OVER (
    ORDER BY BOOKING_DATE ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ) as "DIFF_BTW_ACTUAL_AVG"
FROM {{ ref('prepped_data') }}
```


![](pic/2024-05-08-19-15-22.png)


# Airflow DAGの準備


```
cd ../dags
vi init.py
vi transform_and_analysis.py
```


```init.py

from datetime import datetime
import os

from airflow import DAG
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.dummy_operator import DummyOperator

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2020,8,1),
    'retries': 0
}


with DAG('1_init_once_seed_data', default_args=default_args, schedule_interval='@once') as dag:
    task_1 = BashOperator(
        task_id='load_seed_data_once',
        bash_command='cd /dbt && dbt seed --profiles-dir .',
        env={
            'dbt_user': '{{ var.value.dbt_user }}',
            'dbt_password': '{{ var.value.dbt_password }}',
            **os.environ
        },
        dag=dag
    )

task_1  

```

``` transform_and_analysis.py
from airflow import DAG
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.dummy_operator import DummyOperator
from datetime import datetime


default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2020,8,1),
    'retries': 0
}

with DAG('2_daily_transformation_analysis', default_args=default_args, schedule_interval='@once') as dag:
    task_1 = BashOperator(
        task_id='daily_transform',
        bash_command='cd /dbt && dbt run --models transform --profiles-dir .',
        env={
            'dbt_user': '{{ var.value.dbt_user }}',
            'dbt_password': '{{ var.value.dbt_password }}',
            **os.environ
        },
        dag=dag
    )

    task_2 = BashOperator(
        task_id='daily_analysis',
        bash_command='cd /dbt && dbt run --models analysis --profiles-dir .',
        env={
            'dbt_user': '{{ var.value.dbt_user }}',
            'dbt_password': '{{ var.value.dbt_password }}',
            **os.environ
        },
        dag=dag
    )

    task_1 >> task_2 # Define dependencies

```

# Airflowのdocker-composeファイルの実行

docker desktopを起動し、以下のコマンドを実行します。
```
cd ../
docker-compose up
```

もし次のエラーが出た時`Bind for 0.0.0.0:8080 failed: port is already allocated`
次のコマンドを実行して、ポートを解放します。
```
docker container ls
docker rm -f <container-name>
```

`docker-compose up`実行後、以下のURLにアクセスします。
http://localhost:8080/

うまくいけば、以下の画面が表示されます。

立ち上がらない場合、
`.env`ファイルの`_PIP_ADDITIONAL_REQUIREMENTS`が正しく設定されているか確認してください。

![](pic/2024-05-10-19-51-12.png)


```
ユーザ名: airflow
パスワード: airflow
```

Admin > Variables > Createをクリックし、以下の変数を追加します。

![](pic/2024-05-11-00-56-20.png)


+ボタンより以下の変数を追加します。

```
dbt_account: xxxx
dbt_user: xxxx
dbt_password: xxxx
dbt_database: xxxx_DB
dbt_warehouse: xxxx_WH
dbt_schema: AIRFLOW_DBT
```

![](pic/2024-05-11-00-57-25.png)

![](pic/2024-05-11-00-58-33.png)


右端の１、２を有効にし左端の再生ボタンをクリックします。

![](pic/2024-05-11-00-59-00.png)

![](pic/2024-05-11-00-59-23.png)


successが表示されたら、成功です

また、snowflakeにアクセスすると、以下のようにテーブルが作成されていることが確認できます。

![](pic/2024-05-11-01-00-09.png)

![](pic/2024-05-11-01-04-11.png)



![](pic/2024-05-11-01-10-23.png)

![](pic/2024-05-11-01-11-24.png)



## Required "name" field not present in project

https://quickstarts.snowflake.com/guide/data_engineering_with_apache_airflow_ja/index.html?index=..%2F..index#2


> 最後のステップは、db_utilsのdbtモジュールをインストールすることです。dbtディレクトリから次を実行します。
> dbt deps


console output:
```
dbt deps
00:34:17  Running with dbt=1.7.14
00:34:17  Encountered an error:
Runtime Error
  Required "name" field not present in project
```

fix:dbt_project.yml
```
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

## macrosフォルダの下

https://quickstarts.snowflake.com/guide/data_engineering_with_apache_airflow_ja/index.html?index=..%2F..index#2


> ここで、macrosフォルダの下にcustom_demo_macros.sqlというファイルを作成し

> 関連するモジュールがdbt_modulesフォルダにインストールされていることがわかります。
> ここまでで、次のようなフォルダ構造になります。

![](pic/2024-05-08-09-44-04.png)

note: `custom_demo_macros.sql`か`macro.sql`のどちらのファイル名にするか

fix: `custom_demo_macros.sql`に変更
画像修正
![](pic/2024-05-08-09-41-11.png)



# airflowの起動時エラー

https://quickstarts.snowflake.com/guide/data_engineering_with_apache_airflow_ja/index.html?index=..%2F..index#5

airflowの起動時エラーが出る
```
Broken DAG: [/opt/airflow/dags/transform_and_analysis.py]
Traceback (most recent call last):
  File "<frozen importlib._bootstrap>", line 488, in _call_with_frames_removed
  File "/opt/airflow/dags/transform_and_analysis.py", line 21, in <module>
    **os.environ
      ^^
NameError: name 'os' is not defined. Did you forget to import 'os'
```

fix: `transform_and_analysis.py`に`import os`を追加し、リロードする
```python
from airflow import DAG
from airflow.operators.python import PythonOperator, BranchPythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.dummy_operator import DummyOperator
from datetime import datetime
import os
```


## airflowが起動しない

https://quickstarts.snowflake.com/guide/data_engineering_with_apache_airflow_ja/index.html?index=..%2F..index#6 

.envファイルを以下のようにする
```
_PIP_ADDITIONAL_REQUIREMENTS=dbt-snowflake==1.7.3
```
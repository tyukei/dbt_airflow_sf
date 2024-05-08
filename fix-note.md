

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
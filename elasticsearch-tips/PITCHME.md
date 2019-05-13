### Elasticsearch TIPS

#### 2019-05-14

---

![Cluster](elasticsearch-tips/assets/images/cluster.PNG)

---

![Mapping](elasticsearch-tips/assets/images/mapping.PNG)

---

### トピック

- 文字列の完全一致検索をしたい
- index の設定は途中で変えられない (ものがある)
- EBS ではなく instance store
- 正確な cardinality 計算はできない
- Index Alias
- Routing
- Shard Allocation Awareness
- Shard Allocation Filtering
- Split Brain の防止

---

### 文字列の完全一致検索をしたい

- (v2.x の) デフォルトでは string 型は analyze される
  - analyze 処理で tokenize されてしまう
  - IFA で検索しても引っかからない...みたいになる
- 全文検索したいフィールドでないなら `not_analyzed` にするべき

```
# v2.x
$ curl http://localhost:9200/index1/_mappings
{
  "index1": {
    "mappings": {
      "typ1": {
        "properties": {
          "applicationId": {
            "type": "string",
            "index": "not_analyzed"
          },
          ...
        }
        ...
```

### 文字列の完全一致検索をしたい

- v5.x 以降でいう keyword type と同等

```
# v5.x 以降
$ curl http://localhost:9200/index1/_mappings
{
  "index1": {
    "mappings": {
      "properties": {
        "applicationId": {
          "type": "keyword"
        },
        ...
      }
      ...
```

---

### 資料まとめ

- [README of tiqwab/slides/elasticsearch-tips][1]

[1]: https://github.com/tiqwab/slides/tree/master/elasticsearch-tips

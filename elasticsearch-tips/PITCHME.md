### Elasticsearch TIPS

#### 2019-05-14

---

![Cluster](elasticsearch-tips/assets/images/cluster.PNG)

---

![Mapping](elasticsearch-tips/assets/images/mapping.PNG)

---

### トピック

- 文字列の完全一致検索
- Index 設定の変更
- EBS ではなく instance store
- 正確な cardinality 計算はできない
- Index Alias
- Routing
- Shard Allocation Awareness
- Shard Allocation Filtering
- Split Brain の防止

---

### 文字列の完全一致検索

- (v2.x の) デフォルトでは string 型は analyze される
  - analyze 処理で tokenize されてしまう
  - IFA で検索しても引っかからない...みたいになる
- 全文検索したいフィールドでないなら `not_analyzed` にするべき

```json
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

---

### 文字列の完全一致検索

- v5.x 以降でいう keyword type と同等

```json
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

### Index 設定の変更

- 一度稼働し始めた index では変更できない設定がある
- 変えられない設定
  - mapping
    - `not_analyzed` にするために reindex した経験あり
  - shard 数
    - データが増えると shard サイズは増える一方

---

### Reindex

- 欲しい index 定義にした上でまるっとデータを入れ直す
- 専用の API あり (ただし stable になったのは v5.0 以降)
- 高速な reindex のためにはいくつか考慮すべき設定、変数がある
  - replica 数
  - `refresh_interval`
  - 一度にバルク処理するドキュメント数

---

### 資料まとめ

- [README of tiqwab/slides/elasticsearch-tips][1]

[1]: https://github.com/tiqwab/slides/tree/master/elasticsearch-tips

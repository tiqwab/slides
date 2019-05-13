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
- EC2 でクラスタ構築する際の考慮点
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
    - not\_analyzed にするために reindex した経験あり
  - shard 数
    - データが増えると shard サイズは増える一方

---

### Reindex

- 欲しい index 定義にした上でまるっとデータを入れ直す
- 専用の API あり (ただし stable になったのは v5.0 以降)
- 高速な reindex のためにはいくつか考慮すべき設定、変数がある
  - replica 数
  - refresh\_interval
  - 一度にバルク処理するドキュメント数

---

### EC2 でクラスタ構築する際の考慮点

- EBS or Instance Store
- Shard Allocation Awareness

---

### EBS or Instance Store

- EBS
  - ネットワーク経由のアクセスになる
  - インスタンスが停止、終了してもデータは残る
- instance store
  - 物理的に接続されたディスクへのアクセス
  - インスタンスが停止、終了するとデータは消える (再起動は除く)

---

### EBS or Instance Store

- [Best Practices in AWS][2] では instance store を推奨
- 大規模 cluster で安く性能を出すなら instance store

---

### Shard Allocation Awareness

- primary と replica shard の配置を何らかコントロールしたい場合に使う
  - 例. 同じラック上の node には同じ shard の primary と replica が配置したくない
- AWS 上だと availability zone でわけるべき
  - [AWS Cloud Plugin][3] ではそうなっている

```
# in /etc/elasticsearch/elasticsearch.yml
#
# 各 node には node.attr.aws_availability_zone = ap-northeast-1 のような設定が
# plugin で入っている前提
cluster.routing.allocation.awareness.attributes: aws_availability_zone
```

---

### 資料まとめ

- [README of tiqwab/slides/elasticsearch-tips][1]

[1]: https://github.com/tiqwab/slides/tree/master/elasticsearch-tips
[2]: https://www.elastic.co/guide/en/elasticsearch/plugins/master/cloud-aws-best-practices.html
[3]: https://www.elastic.co/guide/en/elasticsearch/plugins/2.4/cloud-aws.html

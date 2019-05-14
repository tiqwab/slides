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
- 正確な cardinality 計算
- Routing
- Index Alias の活用
- Split Brain の防止
- Shard Allocation Filtering

---

### 文字列の完全一致検索

- (v2.x の) デフォルトでは string 型は analyze される
  - analyze 処理で tokenize されてしまう
  - IFA で検索しても引っかからない...みたいになる
- 全文検索したいフィールドでないなら `not_analyzed` に

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
  - mapping
    - not\_analyzed にするために reindex した経験あり
  - shard 数
    - データが増えると shard サイズは増える一方

---

### Reindex

- 欲しい index 定義にした上でまるっとデータを入れ直す
- 専用の API あり (ただし stable になったのは v5.0 以降)
- 高速な reindex のためにはいくつか考慮が必要
  - replica 数を 0 にする
  - refresh\_interval を 0 にする
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
  - 例. primary と replica shard を同じラック上の node には配置したくない
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

### 正確な cardinality 計算

- Elasticsearch には正確な cardinality 計算方法がない
  - 限られたリソースでは任意の cardinality は扱えない
- 代わりに HyperLogLog++ という確率的アルゴリズムを使用する
  - cardinality 100 万ぐらいなら 1% ぐらいの誤差に抑えられる

---

### Routing

- `_routing` によって保存先の shard が決まる
  - デフォルトは `_id`
- `_routing` を指定することで特定の検索パフォーマンスを向上できる

```
shard_num = hash(_routing) % num_primary_shards
```

---

### Index Alias の活用

- Index に別名をつける
  - cluster 外からは同じ index 名だけど実体は異なるみたいなことができる
  - 1 alias で複数 index 指定も可能
- Elasticsearch を使うならはじめに設定しておきたい

---

### Index Alias の活用

![index-alias1](elasticsearch-tips/assets/images/index-alias1.PNG)

---

### Index Alias の活用

- Alias が活きる場面例
  - rollover
  - reindex
  - routing

---

### Split Brain の防止

From Wikipedia 「スプリットブレインシンドローム」:

> スプリットブレインシンドロームとは、複数のコンピュータを相互接続して1台のサーバのように動作させるシステムにおいて、ハードウェアやインターコネクトの障害によりシステムが分断され、1つのサービスがクラスタ内の複数のノード群で同時に起動してしまい、サービス供給が停止してしまう状況のこと

---

### Split Brain の防止

![split-brain1](elasticsearch-tips/assets/images/split-brain1.PNG)

---

### Split Brain の防止

![split-brain2](elasticsearch-tips/assets/images/split-brain2.PNG)

---

### Split Brain の防止

- `discovery.zen.minimum_master_nodes` を master eligible の過半数となる数字に設定する
  - master eligible 3 台なら 2
- ただ latest の 7.x なんかだと master eligible な node を指定するようになっていて、`minimum_master_nodes` という設定は deprecated になっているっぽい

---

### Shard Allocation Filtering

- shard を配置する node をコントロールできる
- 稼働中のシステムに alias を設定するために利用した
- いまはもういらないかも

```
# node 名を利用した filtering 設定
$ curl http://localhost:9200/index1/_settings | jq .
{
  "index1": {
    "settings": {
      "index": {
        "routing": {
          "allocation": {
            "include": {
              "_name": "node1,node2,node3"
            }
          }
        }
      }
    }
  }
}
```

---

### 資料まとめ

- [README of tiqwab/slides/elasticsearch-tips][1]

[1]: https://github.com/tiqwab/slides/tree/master/elasticsearch-tips
[2]: https://www.elastic.co/guide/en/elasticsearch/plugins/master/cloud-aws-best-practices.html
[3]: https://www.elastic.co/guide/en/elasticsearch/plugins/2.4/cloud-aws.html

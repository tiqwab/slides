### おさらい

前回のスライド使って

### (v2.x) `not_analyzed` 設定

- (v2.x) string type で `not_analyzed` を設定しないと完全一致検索ができない
- (v5.x) 以降でいう keyword type と同等

```
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

```
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

参考:

- [Strings are dead, long live strings!][1]

### index の設定を途中で変えられない (ものが多い)

- 変えられない設定
  - 例えば mapping
    - `not_analyzed` にするために reindex した
  - 例えば shard 数の変更
- reindex
  - API も提供されている (が stable になったのは 5.0 以降)
  - 高速な reindex 処理のための設定、変数
    - replica 数
    - `refresh_interval`
    - 一度にバルク処理するドキュメント数

参考:

- https://www.elastic.co/guide/en/elasticsearch/guide/current/indexing-performance.html
- https://blog.cybozu.io/entry/2016/08/18/100000

### Use instance store not EBS (on AWS)

- EBS
  - ネットワーク経由のアクセスになる
  - インスタンスが停止、終了してもデータは残る
- instance store
  - 物理的に接続されたディスクへのアクセス
  - インスタンスが停止、終了するとデータは消える (再起動は除く)

多分安く性能を出すために instance store を選んでいる?
[Best Practices in AWS][3] でも推奨は instance store な感じ。

### 正確な cardinality の計算をサポートしていない

- cardinality: いわゆる `distinct count`
- 限定されたリソース (e.g. メモリ) では任意の cardinality は扱えない
- Elasticsearch では HyperLogLog++ という確率的アルゴリズムを使用
  - 精度の設定次第だけど cardinality が 100 万ぐらいなら 1 % の誤差に抑えられる?

参考:

- [Count-distinct problem][4]
- [Approximate Aggregations][5]
- [Cardinality Aggregation][6]

### Index Alias の利用

- Index に別名をつける
  - cluster 外からは同じ index 名だけど実体は異なるみたいなことができる
  - 1 alias で複数 index 指定も可能
- 有用な一例
  - rollover
  - reindex
  - routing との組み合わせ
- 感じとしては IP に対するドメイン名のような
- Elasticsearch を使うならはじめに設定しておきたい

参考:

- [Elasticsearch インデックス・エイリアス][7]
- [Index Aliases][8]

### Routing 設定

`_routing` によって保存先の shard が決まる。デフォルトは `_id`。

```
shard_num = hash(_routing) % num_primary_shards
```

- `_routing` を指定することで特定の検索パフォーマンスを向上できる
- Alias と組み合わせれば特定の routing を持つデータだけ別 index にしたりできる

参考:

- [User-Based Data][9]
- [routing field][10]

### Shard Allocation Awareness

- 例えば同じラック上の node に primary と replica が配置されないようにしたいみたいな要求を満たすためのもの
  - AWS 上だと availability zone でわけるのが適切かと
  - [AWS Cloud Plugin][14] ではそうなっている

`/etc/elasticsearch/elasticsearch.yml`:

```
# 各 node には node.attr.aws_availability_zone = ap-northeast-1 のような設定が plugin で入っている前提
cluster.routing.allocation.awareness.attributes: aws_availability_zone
```

参考:

- [Shard allocation awareness][13]

### Shard Allocation Filtering

- 例えばこの index の shard はこの node に配置したくないというような要求を満たすためのもの
- いまのシステムだと新しい node を追加するときに更新しないといけないというだけでただ邪魔者になっているかも
  - 元々は稼働中のシステムに alias を設定するために利用した

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

参考:

- [Index-level shard allocation filtering][11]
- [Cluster-level shard allocation filtering][12]

### Split Brain の防止

- `discovery.zen.minimum_master_nodes` を master eligible の過半数となる数字に設定する
  - master eligible 3 台なら 2
- ただ latest の 7.x なんかだと master eligible な node を指定するようになっていて、`minimum_master_nodes` という設定は deprecated になっているっぽい

参考:

- [Minimum Master Nodes][15]
- [Breaking changes in 7.0][16]

[1]: https://www.elastic.co/jp/blog/strings-are-dead-long-live-strings
[3]: https://www.elastic.co/guide/en/elasticsearch/plugins/master/cloud-aws-best-practices.html
[4]: https://en.wikipedia.org/wiki/Count-distinct_problem
[5]: https://www.elastic.co/guide/en/elasticsearch/guide/current/_approximate_aggregations.html
[6]: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-cardinality-aggregation.html
[7]: https://medium.com/hello-elasticsearch/elasticsearch-c8c9c711f40
[8]: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html
[9]: https://www.elastic.co/guide/en/elasticsearch/guide/current/user-based.html
[10]: https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-routing-field.html
[11]: https://www.elastic.co/guide/en/elasticsearch/reference/current/shard-allocation-filtering.html
[12]: https://www.elastic.co/guide/en/elasticsearch/reference/current/allocation-filtering.html
[13]: https://www.elastic.co/guide/en/elasticsearch/reference/current/allocation-awareness.html
[14]: https://www.elastic.co/guide/en/elasticsearch/plugins/2.4/cloud-aws.html
[15]: https://www.elastic.co/guide/en/elasticsearch/guide/1.x/_important_configuration_changes.html#_minimum_master_nodes
[16]: https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-7.0.html

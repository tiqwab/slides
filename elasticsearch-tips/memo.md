### (v2.x) `not_analyzed` 設定

- (v2.x) string type で `not_analyzed` を設定しないと完全一致検索ができない
- (v5.x) 以降でいう keyword type と同等

参考:

- [Strings are dead, long live strings!][1]

### index の設定を途中で変えられない (ものが多い)

- 変えられない設定
  - 例えば mapping
    - `not_analyzed` にするために reindex した
  - 例えば shard 数の変更
- reindex
  - API も提供されている (が stable になったのは 5.0 以降)
  - 性能を左右し得る設定、変数
    - replica 数
    - `refresh_interval`
    - 一度にバルク処理するドキュメント数

参考:

- https://www.elastic.co/guide/en/elasticsearch/guide/current/indexing-performance.html
- https://blog.cybozu.io/entry/2016/08/18/100000

### Use instance store not EBS (on AWS)

- EBS
  - 物理的に接続されていない
    - ネットワークを経由したアクセス
  - インスタンスが停止、終了してもデータは残る
- instance store
  - 物理的に接続されたディスク
  - インスタンスが停止、終了するとデータは消える (再起動は除く)

多分安く性能を出すために instance store を選んでいる?
[Best Practices in AWS][3] でも推奨は instance store な感じ。

### 正確な cardinality 計算をサポートしていない

- cardinality: いわゆる `distinct count`
- 限定されたリソースでは任意の cardinality は扱えない
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

### Shard Allocation Filtering

### Split Brain の防止

[1]: https://www.elastic.co/jp/blog/strings-are-dead-long-live-strings
[3]: https://www.elastic.co/guide/en/elasticsearch/plugins/master/cloud-aws-best-practices.html
[4]: https://en.wikipedia.org/wiki/Count-distinct_problem
[5]: https://www.elastic.co/guide/en/elasticsearch/guide/current/_approximate_aggregations.html
[6]: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-cardinality-aggregation.html
[7]: https://medium.com/hello-elasticsearch/elasticsearch-c8c9c711f40
[8]: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html
[9]: https://www.elastic.co/guide/en/elasticsearch/guide/current/user-based.html
[10]: https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-routing-field.html

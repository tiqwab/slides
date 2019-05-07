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

### Use instance store not EBS

- EBS
  - 物理的に接続されていない
    - ネットワークを経由したアクセス
  - インスタンスが停止、終了してもデータは残る
- instance store
  - 物理的に接続されたディスク
  - インスタンスが停止、終了するとデータは消える (再起動は除く)

多分安く性能を出すために instance store を選んでいる?
[Best Practices in AWS][3] でも推奨は instance store な感じ。

[3]: https://www.elastic.co/guide/en/elasticsearch/plugins/master/cloud-aws-best-practices.html

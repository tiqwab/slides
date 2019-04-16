### Elasticsearch とは

- 分散型 RESTful 検索、分析エンジン

### General Concepts

ref. [General Concepts][1]

- Cluster
- Node
- Index
- (Type)
- Document
- Shards
- Replicas

### 簡単に CRUD

---

[Elasticsearch: The Definitive Guide][2] を読んでいく
2.x 系での話なのでいまは内容が古くなっている可能性高いけど

- Getting Started
  - Getting Started は Elasticsearch の使用例を挙げるのに良さそう
  - Elasticsearch 登場時のアピールポイントは以下の 2 つを併せ持つことだったっぽい
    - 全文検索ができる
    - 分散データストアである
  - Apache Lucene という全文検索エンジンのライブラリを使用している
    - この機能を RESTful API でわかりやすく提供するというのも目的だった？
- Life Inside a Cluster
  - 図が cluster, node, shard, node.master, node.data の概念の説明に良さそう
    - 1 empty node
    - 1 node with an index
    - 3 node with an index
    - 1 台 node が落ちたとき
  - shard が Apache Lucene の 1 インスタンスである、というのは興味あるけどスライドでは触れないほうが良さげ
- Distributed Document Store
  - Elasticsearch では document の CRUD リクエストをどの node に投げても良い (というか負荷軽減のために分散させた方がいいぐらい)
    - 各 node はそのドキュメントが格納される shard がどの node にいるのか知っているので、対象 node にリクエストを forward する
  - C, U, D リクエストについてはまず primary に変更が適用される
  - replica にも変更を反映させてからレスポンスを返すみたい
    - つまりリクエスト側から見れば、成功した場合、primary, replica ともに変更が反映されたことが保証されるということになる
    - ただこれ [いまは違うのかも][3]。primary に反映されれば replica への反映も待たずレスポンスを返す。実感的にも確かにそう
    - そしてこれは検索可能とは別の話なはず
  - R リクエストについては primary, replica に分散して問い合わせる
- Distributed Search Execution
  - 受け付けた search リクエストの解決の様子が示されている
    - リクエストを受け取った node が各 shard の結果を集めるために他の node に問い合わせる
    - リクエストを受け取った node は各 node からの結果を集めてレスポンスを作る
- Inside a Shard
  - 作成された inverted index は immutable
  - Lucene では segment の集合と commit point というのを合わせて index と呼ぶ
    - Elasticsearch ではこれを shard と呼んでいる
  - segment は inverted index
  - 更新を扱うためには新しい差分用の segment を作成する
  - 新しいドキュメントの保存の流れは
    - in memory のセグメントに保存 (not searchable)
      - ここで translog にも書き込まれる (RDB のそれと似た概念)
      - restart 時に in memory buffer や disk cache にしかないセグメントを復元するために使われるっぽい
    - 定期的に
      - in memory から disk に書き込まれる
        - ここで OS の disk cache にいるだけ、でも searchable という状態があるっぽい?
        - この searchable にする状態を Elasticsearch では refresh と呼んでいる
        - よく reindex 時に設定する `refresh_interval` はこれのこと
      - commit point も更新して disk に
        - Elasticsearch ではこれを flush と呼んでいる
    - セグメントが searchable になる
    - in memory のセグメントをクリアする
  - つまり search 時の対象セグメントは複数になる
  - 更新や削除もセグメントに追記する感じで、既存のセグメントを触ることはない
  - 検索と違い CRUD は real-time だと言っている
    - これは translog のためと
    - id で引っ張るときに translog もチェックしている
  - これだとセグメントがどんどん増えるので、バックグラウンドでセグメントを merge するという処理がある
    - スクロールではある時点の snapshot のようなものを見れるが、そのときには使用しているセグメントが merge されると困るので、そこらへんの確認はされているらしい

[1]: https://www.elastic.co/guide/en/elasticsearch/reference/current/getting-started-concepts.html
[2]: https://www.elastic.co/guide/en/elasticsearch/guide/current/index.html
[3]: https://github.com/elastic/elasticsearch/issues/16728

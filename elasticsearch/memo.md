### Elasticsearch とは

- 分散型 RESTful 検索、分析エンジン

データ分析基盤構築入門 P.194 より

> - OSS (Apache License v2)
> - ドキュメント指向
>   - ドキュメント単位でフィールドの定義ができるため、柔軟なデータの登録ができる
> - 分散システム
>   - インデックスを分散して保持し、検索する。スケールアウトを当初から想定した設計
> - マルチテナント
>   - 複数のインデックスを登録できる
> - RESTful な API
>   - データの操作や設定、監視などの必要な機能が HTTP インタフェースで利用できる
> - (near) リアルタイム
>   - (ほぼ) データをリアルタイムで検索できる

### General Concepts

ref. [General Concepts][1]

- Cluster
- Node
- Index
- (Type)
- Document
- Shards
- Replicas

1 node 1 shard から徐々に登場人物を増やしていく感じで

#### 稼働しているシステムの場合

- 計 9 node で 1 index 128 shards, 1 replica

### 簡単に CRUD 例

### Document

- mapping
  - field types (in v7.0)
    - text
    - keyword
      - v2.4 でいう `not_analyzed` な string
    - long
    - date

### master node のお仕事

- cluster state の管理
  - cluster state 自体は各 node にも渡されるが、変更できるのは master だけ
  - 例
    - cluster-level settings
    - cluster を構成する node の管理 (add, remove)
    - index settings, mappings, analyzers, warmers, and aliases
    - shard の割り当て (どの node にいるか)

### data node のお仕事

- shards (つまり documents) を保存する
- クエリに応じて自身の shards の検索結果を返す

#### 稼働しているシステムの場合

3 台が master 専用、6 台が data 専用

- master, data は兼任できるが、本番環境では分けるのが推奨される
- master は 2 台が予備として待機している
- indexing のリクエストを受け付けるのは data のみ
  - master には負荷をかけないのが吉

### (near) リアルタイム

- indexing
  - [はじめての Elasticsearch クラスタ][6] の P19 ぐらいが参考になる
- refresh と flush
  - [Elasticsearch: The Definitive Guide][2] の Inside a Shard
  - [Guide to Refresh and Flush Operations in Elasticsearch][7]
- merge

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
    - ただ上では 5.x ではそうではなくなっていると言っている人もいるしよくわからん
  - これだとセグメントがどんどん増えるので、バックグラウンドでセグメントを merge するという処理がある
    - スクロールではある時点の snapshot のようなものを見れるが、そのときには使用しているセグメントが merge されると困るので、そこらへんの確認はされているらしい
- Aggregations
  - cardinarity の計算には HyperLogLog という確率論的アルゴリズムが使われている
    - 必ずしも正しい値が返るわけではない
- Modeling Your Data
  - primary shard が nodes に均等に分配されていないといけないということはない
  - 1 index 50 shards と 50 index 1 shard は Elasticsearch 的には同じ話にできる
    - なので例えばログデータを入れるときに 1 日 index とかにする設計は過去データの扱いに気をつければ全然あり
- [master node のやることの一例][4]
- [Scale is Not Infinite][5]
- mapping 多くなりすぎる問題はうちの tag の使い方でもありうる？
  - nexted object を本来は使うべき？
    - これだと Elasticsearch の制限で tag の数は最大 10000 になる
  - 応急処置としては別 index に逃がすとかはできるのかもしれないけど

---

- indexing のリクエストは master でも data でも受け付けられる
  - ただ負荷をかけたくないと言う意味で master は避けるべきとのこと

---

### 疑問

- 複数 index を持つクラスタの場合、index 毎に master は変わったりしないよね？

### TODO

- [x] 未作成スライドの対応
- [x] topics の追加
- [ ] 冗長性について触れるために node が落ちたときの例を入れる？
- [x] 参考元の整理

[1]: https://www.elastic.co/guide/en/elasticsearch/reference/current/getting-started-concepts.html
[2]: https://www.elastic.co/guide/en/elasticsearch/guide/current/index.html
[3]: https://github.com/elastic/elasticsearch/issues/16728
[4]: https://www.elastic.co/guide/en/elasticsearch/guide/current/finite-scale.html
[5]: https://www.elastic.co/guide/en/elasticsearch/guide/current/finite-scale.html
[6]: https://www.slideshare.net/snuffkin/elasticsearch-107454226
[7]: https://qbox.io/blog/refresh-flush-operations-elasticsearch-guide

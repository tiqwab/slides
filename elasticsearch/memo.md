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

[1]: https://www.elastic.co/guide/en/elasticsearch/reference/current/getting-started-concepts.html
[2]: https://www.elastic.co/guide/en/elasticsearch/guide/current/index.html

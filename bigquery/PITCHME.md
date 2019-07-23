## BigQuery

### 2019-07-23

---

### トピック

- BigQuery とは
- クエリについて
- 課金
- データインポート
- データエクスポート

---

### BigQuery とは

- サーバレスクラウドデータウェアハウス
  - インフラストラクチャの管理が不要
  - クエリのパフォーマンスよい
- クエリ言語として SQL を使用
  - SQL:2011 に準拠
  - ネストした構造をサポートする拡張
- 従量課金
  - ストレージ
  - クエリ

---

### 2 つの SQL 言語

- 標準
  - SQL:2011 準拠
- レガシー
  - 基本忘れていい

現状レガシーが消えるといった予定は無いみたいですが、率先してそちらを使用する理由はあまりないと思います。

標準 SQL 例:

```sql
SELECT COUNT(*) FROM `bigquery-public-data.github_repos.sample_commits`;
```

---

### スキーマ

- データ投入前にスキーマを決める
  - 動的に (データ投入時に) スキーマを推測してもらうのも可
- スキーマ例
  - 稼働中のイベントテーブルより一部抜粋

```json

```

---

### WITH 句

```sql
WITH sample AS (
  SELECT [
    STRUCT('Alice' AS name, 25 AS age),
    STRUCT('Bob' AS name, 23 AS age)
   ] AS person
)
SELECT * FROM sample;
```

結果:

```json
[
  {
    "person": [
      {
        "name": "Alice",
        "age": "25"
      },
      {
        "name": "Bob",
        "age": "23"
      }
    ]
  }
]
```

WITH 句を使わない場合

```sql
SELECT * FROM (
  SELECT [
    STRUCT('Alice' AS name, 25 AS age),
    STRUCT('Bob' AS name, 23 AS age)
  ] AS person
) AS sample;
```

---

### UNNEST 関数

- 繰り返しのある構造をフラットにする

```sql
WITH sample AS (
  SELECT * FROM UNNEST([
    STRUCT('Alice' AS name, 25 AS age),
    STRUCT('Bob' AS name, 23 AS age)
   ]) AS person
)
SELECT * FROM sample;
```

結果:

```json
[
  {
    "name": "Alice",
    "age": "25"
  },
  {
    "name": "Bob",
    "age": "23"
  }
]
```

---

### 応用例

- 0-9 の digit を使って 1-1000 までの整数を生成し、FizzBuzz を出力する

```sql
WITH digits AS (
  SELECT * FROM UNNEST(GENERATE_ARRAY(0, 9)) AS n
),
generated_numbers AS (
  SELECT (a.n * 100 + b.n * 10 + c.n) + 1 AS n
  FROM digits a, digits b, digits c
)
SELECT CASE WHEN MOD(n, 15) = 0 THEN 'FizzBuzz'
                  WHEN MOD(n, 3) = 0 THEN 'Fizz'
                  WHEN MOD(n, 5) = 0 THEN 'Buzz'
                  ELSE CAST(n AS STRING) END
FROM generated_numbers ORDER BY n;
```

~~はじめから `GENERATE_ARRAY(1, 1000)` でいいのでは？~~

BigQuery には色々な関数があるので困ったときには[関数一覧][3]を見るといいかも。

---

### DML

- DML (Data Manipuration Languate, データ操作言語)
- サポートされている構文
  - UPDATE
  - INSERT
  - DELETE
  - MERGE
- クエリ実行時にスキャンしたデータ量で課金発生
- 一日に発行できる数には制限がある
  - テーブルごとの INSERT, UPDATE, DELETE, MERGE をあわせた一日あたりの最大数 1000

既存テーブルにデータを入れる場合は読み込みジョブ (後述) を使うことが多いはず。

---

### クエリの優先度

- インタラクティブ
  - クエリを投げるとすぐに実行される
  - 同時実行数に制限あり (いまは 100)
- バッチ
  - BigQuery の余裕があるときに実行される
    - とはいっても通常だと 2-3 分後には実行されている
  - 同時実行数の制限なし

---

### 課金

- ストレージ
  - 保存データ量の従量課金
  - $0.020 per GB
  - $0.010 per GB (90 日間 unmodified なデータ)
  - c.f. S3 標準 $0.025 per GB、Glacier $0.002 per GB
- クエリ
  - スキャンしたデータ量の従量課金
  - $5 per TB (on demand)

---

### お財布に優しいクエリ、テーブル設計

- 必要なカラムに絞る
  - 基本的に行単位ではなくカラム単位でスキャン対象になる
  - おもむろに `SELECT *` とかしない
  - LIMIT, OFFSET したからといって課金対象から外れる... とはならない
- 分割テーブルの使用
  - TIMESTAMP or DATE 型のカラムを指定してテーブルを複数のセグメントに分割できる
  - 指定したカラムを条件に含めば、必要なセグメントにのみスキャンができる
  - 昔は挿入時刻 `_PARTITIONTIME` カラム限定だったが、いまはユーザがカラムを選べる

---

### データインポート

- 読み込みジョブ
  - バッチ取り込み
  - 読み込み元はローカル, GCS, .etc
  - お金はかからない
  - 一日に実行できる数に制限がある
    - 1 テーブル 1000 回 (失敗含む)
    - 1 プロジェクト 100000 回 (失敗含む)
  - インポート例
    - [数百GBのデータをMySQLからBigQueryへ同期する][4]
    - [ZOZOTOWNのDWHをRedshiftからBigQueryにお引越しした話][5]
    - 大規模なマスタデータの (daily) 差分追加について等
- ストリーミングインサート
  - $0.01 per 200 MB
  - サイズは 1 行 1 KB 単位で計算

現状サービスでは

- 手作りのバッチ (読み込みジョブ)
- [fluent-plugin-bigquery][6] (ストリーミングインサート)

でインポートしている。

---

### データエクスポート

- エクスポートジョブ
  - GCS や Cloud DataFlow に流す
  - お金はかからない
  - 一日に実行できる数に制限がある
    - 100,000 回まで
    - 計 10 TB まで
- クエリ結果をちまちま (スクロールで) 取り出す (REST API)
  - お金はかからない (もちろんクエリ自体にはかかる)
  - データサイズが多いと時間がかかる
- [Storage API (beta)][7]
  - 一日の実行制限がない、ラージデータをエクスポートするための API?
  - スキャンしたデータ量で課金: $1.10 per TB

---

### その他

- BigQuery ML
  - BigQuery 上で機械学習モデルの作成や実行が行える
  - [BigQuery ML の概要][8]
  - [BigQuery ML の線形回帰で電力需要予測やってみた][9]
- [Release notes][10] を定期的に見る
  - けっこう頻繁に機能追加や制限の緩和がある
    - e.g. 一日のエクスポートジョブ実行可能数 1000 -> 50000
- 公式ドキュメントはできれば英語を見たほうがいい
  - 日本語は内容が古くなっている場合がある

---

---

(以下、没スライド)

---

---

### スキーマ例

- [Firebase Analytics から BigQuery エクスポート時のスキーマ][2]

一部抜粋して JSON で考えるとこんな感じのデータが入っている。

```json
{
    "app_info": {
        "id": "123"
    },
    "device": {
        "operating_system": "foo",
        "advertising_id": "foo",
        "time_zone_offset_seconds": 0
    },
    "user_id": "123",
    "user_pseudo_id": "foo",
    "user_properties": [
      {
          "key": "country",
          "value": {
              "string_value": "Japan",
              "int_value": null,
              "double_value": null
          }
      },
      {
          "key": "age",
          "value": {
              "string_value": null,
              "int_value": 20,
              "double_value": null
          }
      }
    ],
    "event_date": "20190722",
    "event_timestamp": 1563783867000,
    "event_previous_timestamp": 1563697467000,
    "event_name": "app_foreground",
    "event_params": [
    ]
}
```

- user の id
  - `user_id`: `setUserId` API によってユーザが設定する ID
  - `user_pseudo_id`: システムがふる仮の ID
- ユーザ属性、イベントパラメータの値
  - string, int, double でそれぞれカラムを用意している
- ユーザとデバイスを明確にわけている

[1]: https://github.com/tiqwab/slides/tree/master/bigquery
[2]: https://support.google.com/firebase/answer/7029846?hl=ja&ref_topic=7029512
[3]: https://cloud.google.com/bigquery/docs/reference/standard-sql/functions-and-operators?hl=ja
[4]: https://tech.mercari.com/entry/2018/06/28/100000
[5]: https://speakerdeck.com/shiozaki/moving-zozotown-dwh-from-redshift-to-bigquery
[6]: https://github.com/kaizenplatform/fluent-plugin-bigquery
[7]: https://cloud.google.com/bigquery/docs/reference/storage/
[8]: https://cloud.google.com/bigquery-ml/docs/bigqueryml-intro?hl=ja
[9]: https://medium.com/google-cloud-jp/bigquery-ml%E3%81%AE%E7%B7%9A%E5%BD%A2%E5%9B%9E%E5%B8%B0%E3%81%A7%E9%9B%BB%E5%8A%9B%E9%9C%80%E8%A6%81%E4%BA%88%E6%B8%AC%E3%82%84%E3%81%A3%E3%81%A6%E3%81%BF%E3%81%9F-fd211a8a4ded
[10]: https://cloud.google.com/bigquery/docs/release-notes

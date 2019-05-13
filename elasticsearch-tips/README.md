### Slide

https://gitpitch.com/tiqwab/slides?p=elasticsearch-tips

### References

- `not_analyzed` や keyword タイプについて
  - [Strings are dead, long live strings!][1]
- Reindex について
  - [Indexing Performance Tips][2]
  - [Elasticsearch 5.0.0で再インデクシングの高速化を探求する][3]
- EC2 でクラスタ構築
  - [Best Practive in AWS][4]
  - [AWS Cloud Plugin][5]
- Cardinality と HyperLogLog++
  - [Count-distinct problem][6]
  - [Approximate Aggregations][7]
  - [Cardinality Aggregation][8]
- Routing
  - [User-Based Data][9]
  - [routing field][10]
- Index Alias
  - [Elasticsearch インデックス・エイリアス][11]
  - [Index Aliases][12]
- Split Brain
  - [Minimum Master Nodes][13]
  - [Breaking changes in 7.0][14]

[1]: https://www.elastic.co/jp/blog/strings-are-dead-long-live-strings
[2]: https://www.elastic.co/guide/en/elasticsearch/guide/current/indexing-performance.html
[3]: https://blog.cybozu.io/entry/2016/08/18/100000
[4]: https://www.elastic.co/guide/en/elasticsearch/plugins/master/cloud-aws-best-practices.html
[5]: https://www.elastic.co/guide/en/elasticsearch/plugins/2.4/cloud-aws.html
[6]: https://en.wikipedia.org/wiki/Count-distinct_problem
[7]: https://www.elastic.co/guide/en/elasticsearch/guide/current/_approximate_aggregations.html
[8]: https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-metrics-cardinality-aggregation.html
[9]: https://www.elastic.co/guide/en/elasticsearch/guide/current/user-based.html
[10]: https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-routing-field.html
[11]: https://medium.com/hello-elasticsearch/elasticsearch-c8c9c711f40
[12]: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html
[13]: https://www.elastic.co/guide/en/elasticsearch/guide/1.x/_important_configuration_changes.html#_minimum_master_nodes
[14]: https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-7.0.html

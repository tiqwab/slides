### akka

- [並行処理初心者のためのAkka入門][1]
  - どこまでが actor model の話でどこからが akka 独自の話なのか
  - TypedActor

### プロセス計算

- [マルチスレッドでもActorでもない並行処理][2]

### 並行プログラミング

- [Introduction to Concurrent Programming][4]
- [Future/Promise について][5]

### その他

- concurrent と asynchronous を雑に使っている自分に気付く
  - [What is the difference between concurrency, parallelism and asynchronous methods?][3]
  - 同じカテゴリとして見ているのがそもそも違うかも
- actor model 実用例や実装例
  - [j5ik2o/akka-ddd-cqrs-es-example][6]
  - [History of Falcon, the way to production release][8]
  - [Akka ActorとAMQPでLINEのメッセージングパイプラインをリプレースした話][7]
  - [Scala + Akka: Real world example of high traffic application design][10]
  - [Citybound][11]
- [Erlang(Elixir)の使いどころについて使ってる人から教わった話][9]

[1]: https://www.slideshare.net/sifue/akka-39611889
[2]: https://matsu-chara.hatenablog.com/entry/2015/08/16/110000
[3]: https://stackoverflow.com/questions/4844637/what-is-the-difference-between-concurrency-parallelism-and-asynchronous-methods
[4]: https://www.ocf.berkeley.edu/~fricke/threads/threads.html
[5]: http://dwango.github.io/scala_text_previews/trait-tut/future-and-promise.html
[6]: https://github.com/j5ik2o/akka-ddd-cqrs-es-example
[7]: https://www.slideshare.net/linecorp/a-9-47983077
[8]: https://speakerdeck.com/j5ik2o/history-of-falcon-the-way-to-production-release
[9]: https://togetter.com/li/977171
[10]: https://engineers.sg/video/scala-akka-real-world-example-of-high-traffic-application-design-singapore-scala-programmers--2843
[11]: https://aeplay.org/citybound

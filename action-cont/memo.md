- はじめに
  - 継続モナドを取り上げるモチベーション
    - 既にコントローラで使われている
    - しかし初見だと触りづらい
- 継続とは
  - 簡単な定義
    - その後に続く計算
  - (限定) 継続を値としてサポートするような言語はあまり無い (雑な表現かも)
    - 有名なのだと Scheme
  - しかし CPS (Continuation Passing Style) を採用すれば継続を扱える
    - 普通に factorial を書く
    - CPS で factorial を書く
      - 激ムズ
      - ただし直接形式から機械的に変換可能
    - 身近な CPS
      - JavaScript のコールバック地獄
      - with 関数によるリソース管理
    - CPS のうれしみ (?)
      - 上のように何らかの I/O や非同期処理が必要なリソースを扱うには知らず知らず使っている
    - CPS のかなしみ (?)
      - 組み合わせづらさ
- モナドとは
  - pure, flatMap を持ち一連の法則を満たす
  - e.g. Option モナド
- 継続モナド
  - 定義
  - 3 つぐらい for で組み合わせる。継続を視覚的に捉える
- 継続モナドと (Web アプリケーションの) コントローラ
  - 簡単な例

---

### 継続モナド

- (!) [並行プログラミングと継続モナド][3]
  - これを説明の元にしたい
- [モナドから始めない継続入門 ][5]
  - 継続モナドを「CPS をモナド化したもの」と捉えていいならば説明の一例になりそう
  - 下の tanakah さんの記事で
    > もっとも直接的な実装は、CPSの関数をモナドのインスタンスにしてしまうというものです
    とあるのでそう考えても良さそう
- [継続モナドによるリソース管理][6]
  - 継続モナドの具体例として

### 継続モナドと Controller

- [継続モナドを使ってWebアプリケーションのコントローラーを自由自在に組み立てる][1]
- [継続モナドを使ってwebアプリケーションのユースケース(ICONIX)を表現/実装する][2]
- [継続モナドが分からなくてもActionContの嬉しさなら何とか分かる気がした。][4]

何にせよ (当たり前だけど) 継続モナドを使わないとできない処理があるわけではない。

- 後続に処理を渡すかを判断できること
- 後続の処理前後に処理を入れられること
  - JavaEE の Servelet Filter に似ている
- それを再利用しやすい形にできること

あたりが継続モナドを controller で使うモチベーションになる

### 他概念と継続

Future, Promise, async/await, callback らへんは非同期で処理を回した後にやりたいことを書く、という点でちょっと継続に似ている気がする。ただここらへんは自分も詳しいわけじゃないし話にはあまり入れない方が良さそう。

- JavaScript の async/await
  - [async function - JavaScript | MDN][7]
  - [コールバック地獄から async/await に至るまでと, 非同期処理以外への応用][8]
- coroutin
  - [https://keens.github.io/blog/2019/02/09/async_awaittogouseikanousei/][9]

[継続渡しスタイル(CPS)再訪、パート1][10]

> 私は、それをJScriptで組み立てるひとつの方法を示した。あらゆる関数が継続を受けとるようにする。新しい継続は、入れ子にされた匿名関数によって必要に応じて作ることができる

これは上の keen さんの記事で「スタックレスコルーチン」と呼んでいるものと考え方は似ていると思う。言語として限定継続がサポートされていない場合にコールスタックを消費せず次の関数を呼び出し続ける方法。

[継続渡しスタイル(CPS)再訪、パート4: 自身をひっくり返す][11]

継続という概念をプログラマが知る理由になりそうな記述

> 私が 継続を面白いと思う理由は、私が言語の 実装 をする側の人間だからだ

コンパイラの最適化とかにはいいことがあるのかも。
[tanakah さんの記事][6] からの引用 (CPS 説明中の言及):

> こんなまどろっこしいことをして何が嬉しいのかというと、実際のところこの例では嬉しい事はなにもないのですが、コンパイラの最適化などでは嬉しいケースも有ります。例えば、CPSにおいては、関数呼び出しは必ず末尾呼び出し、つまりただのジャンプとして扱うことができるのです

あとは非同期処理というのをうまく扱おうとして気付かず継続を扱っている？

非同期処理というのは本質的に (限定) 継続を扱う必要があると言えそう。継続を扱える言語でない場合 CPS 変換して書くことになり、これがいわゆるコールバック地獄化する。
[非同期処理の「その後」の話、goto、継続、限定継続、CPS、そしてコールバック地獄][12]

CPS (callback), Promise の捉え方に混乱中。CPS だと関数にコールバックを渡して非同期処理を組み立てる感じになる。Promise は「将来値が手に入る」という概念を値にして扱いやすくした、という感じ？ Promise の内部実装は結局 CPS だよね、みたいなのもあり得る？
[Promises][13] では state machine として捉えられる、という記述。

### 他資料

- [shift/reset プログラミング入門][14]
  - 浅井先生の資料

[1]: https://qiita.com/pab_tech/items/fc3d160a96cecdead622
[2]: http://labs.septeni.co.jp/entry/2018/03/18/135106
[3]: https://www.slideshare.net/RuiccRail/ss-52718653
[4]: https://matsu-chara.hatenablog.com/entry/2016/02/06/110000
[5]: https://blog.7nobo.me/2018/01/14/01-haskell-continuation.html
[6]: https://qiita.com/tanakh/items/81fc1a0d9ae0af3865cb
[7]: https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Statements/async_function
[8]: https://susisu.hatenablog.com/entry/2016/05/21/224032
[9]: https://keens.github.io/blog/2019/02/09/async_awaittogouseikanousei/
[10]: https://matarillo.com/general/cps01
[11]: https://matarillo.com/general/cps04
[12]: https://keens.github.io/slide/hidoukishorino_sononochi_nohanashi_goto_keizoku_genteikeizoku_CPS_soshiteko_rubakkujigoku_/
[13]: https://www.promisejs.org/implementing/
[14]: http://pllab.is.ocha.ac.jp/~asai/cw2011tutorial/main-j.pdf

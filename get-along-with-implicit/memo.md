### implicit 種類

implicit としてまとめるより個々の機能で見たほうがいいという意見がある (ref. [Scalaでimplicits呼ぶなキャンペーン][7])。

- implicit conversion
  - ライブラリで定義するデータ型に Scala 標準の型を変換したりとか
  - implicit のわかりにくさの犯人はこの子だと思う
    - 例えば いまや非推奨の JavaConversions
    - [罠の例][2]
- implicit class
  - 拡張メソッド (C# にもあるっぽい)
- implicit parameter
  - 引き回すパラメータの省略
    - 否定はしないけど率先して定義はしない
  - 型クラス

### implicit でないと難しいことってある？

- 多分考え方が良くないかも
- 拡張メソッドや型クラスといったものを実現するやり方が Scala の場合 implicit だっただけ的な

### 元々の implicit 導入のモチベーション

- 型クラスを取り入れるため... で良い気がする
- 違う言い方として下の論文の言葉を借りれば concept pattern を使いやすくするためとか

### 型クラスと implicit

- [Type classes as Objects and Implicits][3]

これを参考までに読んでみる。

この論文は型クラスのアイディアをオブジェクト指向プログラミング言語において implicits を利用して実現するアプローチについて述べている。

> Type classeswere originally developed in Haskell as a disciplined  alternative  to  ad-hoc  polymorphism

型クラスってアドホック多相の実現方法の一つという認識だったけど、alternative なの？
あ、いや alternative って代用品みたいな意味で捉えていたけど、本流じゃない何かみたいなニュアンスもあるみたいだから別に認識違いじゃないかも。

(アドホック多相てあまり馴染みがないけど [How to make ad-hoc polymorphism less ad hoc][4] を読むと例えば愚直ではあるけど overload はそう？)

型クラスのユースケースとして

- retroactive extension
  - いわゆるアドホック多相なら元の定義を触らずに ok みたいな話かと
- concept-based C++ style generic programming
- type-level computation

`trait Ord[T]` の例で implicit の良さを語っているけど、結局無いと cumbersome だからというとこになっているな。あとは propagate できるというメリットについて？

P.5 の `implici def OrdPair[A, B]` の例が比較的 implicit の良さがわかるかも。implicit がないとこれは `toPairOrd(ordA, ordB)` みたいな関数をかませる必要がある。一般化すると「この定義があるならこの定義も自動的に導出できるから使っていいよ」みたいなケースでは記述が簡潔になると言えるか？

P.5 後半から CONCEPT パターン について

> Concepts describe a set of requirements for the  type  parameters  used  by  generic  algorithms

Concept パターンで明示的に渡さないといけないパラメータを implicit で省ける。

### Intellij IDEA で implicit 定義の確認

- どの implicit 定義を使っているか
- どこでこの implicit 定義が使われているか

### OOP の継承と型クラス

- どちらも型を分類する仕組みだよね
- 出自は違う
  - 型クラスは FP 側から出てきた概念のはず
- 自分の理解としては特定の操作ができるということを共通化したいなら型クラスを使うほうがしっくりくる
  - 順序付けできるからって Comparable trait を継承して回りたくはないはず

[1]: https://dwango.github.io/scala_text/implicit.html
[2]: https://gist.github.com/xuwei-k/8870ea35c4bb6a4de05c
[3]: http://ropas.snu.ac.kr/~bruno/papers/TypeClasses.pdf
[4]: https://people.csail.mit.edu/dnj/teaching/6898/papers/wadler88.pdf

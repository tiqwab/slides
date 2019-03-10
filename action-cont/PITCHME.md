## 継続モナドについて

### 2019-03-13

---

### はじめに

- 継続モナドを取り上げるモチベーション
  - アプリケーションサーバのコントローラ内で使われている
  - 個人的に読みやすくはあると思う
  - しかし初見だと変更し辛く感じる

```scala
// 例: GitHub の issue を変更するようなエンドポイント
def editIssue(): Action[IssueEditRequest] =
  Action.async { implicit req =>
    val body = req.body
    (for {
      session <- dbCont.getSession // commit if successful, otherwise rollback
      currentIssue <- issueCont.getById(body.issueId) // 404 if not found
      _ <- issueCont.isEditable(currentIssue, body.content)(
        BadRequest("cannot edit issue"))
      _ <- issueCont.update(currentIssue.id, body.content)
    } yield ()).run_
  }
```

---

### 継続とは

- 「その後の計算」を表す概念
  - 引用: [shift/reset プログラミング入門](http://pllab.is.ocha.ac.jp/~asai/cw2011tutorial/main-j.pdf)
- 継続を値としてサポートする言語はあまり無い (らしい)
  - よく聞くのは Scheme とか

---

### CPS

- Continuation Passing Style (継続渡し形式)
- ユーザが CPS で書けば継続を扱える

---

### CPS 変換例

```scala
// ただ 2 をかける
def mult1(n: Int): Int =
  n * 2

// CPS
def mult2[A](n: Int)(f: Int => A): A =
  f(n * 2)

val sample: Int =
  mult2(3)(x => x) // 6
```

---

### 階乗

```scala
// 普通に階乗を求める
def factorial1(n: Int): Int =
  if (n <= 1) 1
  else n * factorial1(n - 1)

// 末尾再帰なら
def factorial2(n: Int): Int = {
  @scala.annotation.tailrec
  def loop(m: Int, acc: Int): Int =
    if (m <= 1) acc
    else loop(m - 1, acc * m)
  loop(n, 1)
}
```

---

### 階乗 in CPS

```scala
// CPS
def factorialCPS[A](n: Int)(cont: Int => A): A =
  if (n <= 1) cont(1)
  else factorialCPS(n - 1)(x => cont(n * x))
```

計算イメージ:

```
factorialCPS(3)(x1 => x1)
factorialCPS(2)(x2 => (x1 => x1)(3 * x2))
factorialCPS(1)(x3 => (x2 => (x1 => x1)(3 * x2))(2 * x3))
(x3 => (x2 => (x1 => x1)(3 * x2))(2 * x3))(1)
(x2 => (x1 => x1)(3 * x2))(2)
(x1 => x1)(6)
6
```

---

### CPS

- わかりにくい
  - 慣れの問題なのかもしれないけど
- ただし機械的に CPS 変換可能
  - コンパイラが内部的に使っていたり？

---

### 身近な CPS

```javascript
// コールバックによる非同期処理
// (e.g. 一昔前の jQuery ajax メソッド)
$.get("http://localhost:9000/", (data) => {
  console.log(data);
});
```

```
// 何らかの前後処理が必要なリソースを扱う
// (e.g. Python3 の 'with' キーワード)
with open('/tmp/foo.txt') as f:
  content = f.read()
  print(content)
```

---

### コールバック地獄

- 複雑な処理になると辛い
- CPS で書かれた関数同士を上手く組み合わせたい
- その 1 つのアプローチがモナド (という理解)

---

### モナド

- 2 つの操作を提供
- モナド則を満たすもの (ここでは省略)

```scala
// 定義例
trait Monad[F[_]] {
  def pure[A](a: A): F[A]
  def flatMap[A, B](fa: F[A])(f: A => F[B]): F[B]
}
```

---

### 例. Option モナド

```scala
implicit def optionMonad: Monad[Option] = new Monad[Option] {
  override def pure[A](a: A): Option[A] =
    Option(a)
  override def flatMap[A, B](fa: Option[A])(f: A => Option[B]): Option[B] =
    fa.flatMap(f)
}
```

---

### for 式

```scala
// pure と flatMap でこんな処理がかける
Option(1).flatMap { x =>
  Option(x + 1).flatMap { y =>
    Option(y * 2)
  }
}
```

```scala
// 上と同じ (糖衣構文)
for {
  x <- Option(1)
  y <- Option(x + 1)
} yield y * 2
```

---

### 継続モナドの定義

```scala
case class Cont[R, A](run: (A => R) => R) {
  def flatMap[B](f: A => Cont[R, B]): Cont[R, B] =
    Cont(g => run(a => f(a).run(g)))
  def map[B](f: A => B): Cont[R, B] =
    flatMap(x => Cont.pure(f(x)))
}

object Cont {
  def pure[R, A](a: A): Cont[R, A] = Cont(f => f(a))
}
```

---

### 継続モナドを試す

```scala

```

---

### 1 枚目

before code

```scala
def foo(x: Int): Int =
  x + 1
```

after code

---

## 2 枚目

This is text. This is text. This is text.
これはテキスト。これはテキスト。これはテキスト。

- one
- two
  - three

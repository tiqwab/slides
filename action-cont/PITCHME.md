## 継続モナドについて

### 2019-03-13

---

### 継続モナドを取り上げる理由

- 既にアプリケーションサーバのコントローラ内で使われている
  - (個人的に) 読みやすくはあると思う
  - しかし初見だと手を付けづらい

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
  override def flatMap[A, B](fa: Option[A])(
      f: A => Option[B]): Option[B] =
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
case class MyFile(name: String) {
  def open(): Unit = println(s"open $name")
  def close(): Unit = println(s"close $name")
  def content: String = s"i am $name"
}

def withFile[R](name: String): Cont[R, MyFile] = Cont { f =>
  val file = MyFile(name)
  file.open()
  try {
    f(file)
  } finally {
    file.close()
  }
}
```

---

### 継続モナドを試す

```scala
lazy val sample1: Unit = {
  val cont: Cont[Unit, String] = for {
    file1 <- withFile("file1.txt")
    file2 <- withFile("file2.txt")
    file3 <- withFile("file3.txt")
  } yield s"${file1.content}. ${file2.content}. ${file3.content}"
  cont.run(println)
}
```

```scala
 scala> sample1
 open file1.txt
 open file2.txt
 open file3.txt
 i am file1.txt. i am file2.txt. i am file3.txt
 close file3.txt
 close file2.txt
 close file1.txt
```

---

### Play Framework

- Scala, Java の Web アプリケーションフレームワーク

```scala
// 単純なコントローラ例
class SampleController(cc: ControllerComponents)
    extends AbstractController(cc) {
  // 各エンドポイントは Action[A] 型 (A はリクエストボディの型)
  def sample1(): Action[AnyContent] = Action.async { req =>
    // Future[play.api.mvc.Result] を返す
    Future.successful(Ok("ok")) // 200 Ok
  }
}
```

---

### ActionCont

```scala
type ActionCont[A] = Cont[Future[Result], A]

// 再掲
case class Cont[R, A](run: (A => R) => R) {
  def flatMap[B](f: A => Cont[R, B]): Cont[R, B] =
    Cont(g => run(a => f(a).run(g)))
  def map[B](f: A => B): Cont[R, B] =
    flatMap(x => Cont.pure(f(x)))
}
```

---

### ActionCont 使用例

```scala
  def editIssue(): Action[IssueEditRequest] =
    Action.async(jsonParser[IssueEditRequest]) { req =>
      val editReq = req.body
      (for {
        conn <- withConnection
        currentIssue <- findIssueById(editReq.id)(conn)
        _ <- isIssueEditable(currentIssue)(BadRequest)
        _ <- updateIssue(editReq.id, editReq.content)
      } yield Ok("ok")).run(Future.successful)
    }
```

@[1-3, 10]
@[4-9]

---

### ActionCont 使用例

```scala
        conn <- withConnection // DB の connection を取得するような
```

```scala
def withConnection(implicit ec: ExecutionContext): ActionCont[MyConnection] =
  ActionCont { f => // f は MyConnection => Future[Result] という継続
    val conn = new MyConnection()
    conn.open()
    try {
      f(conn) map { res =>
        if (is4xx(res) || is5xx(res)) { conn.rollback(); res }
        else { conn.commit(); res }
      }
    } finally {
      conn.close()
    }
  }
```

---

### ActionCont 使用例

```scala
        currentIssue <- findIssueById(editReq.id)(conn)
```

```scala
// リクエストで渡された id でデータ取得
// 見つからなければ 404 で終わる
def findIssueById(id: Long)(implicit conn: MyConnection): ActionCont[Issue] =
  ActionCont { f => // f は Issue => Future[Result] という継続
    Issues.findById(id) match {
      case Some(issue) => f(issue)
      case None        => Future.successful(NotFound)
    }
  }
```

---

### ActionCont 使用例

```scala
        _ <- isIssueEditable(currentIssue)(BadRequest)
```

```scala
def isIssueEditable(issue: Issue)(result: Result): ActionCont[Unit] =
  if (issue.isEditable) {
    ActionCont.pure(())
  } else {
    ActionCont { _ => Future.successful(result) }
  }
```

---

### テスト

```scala
      (for {
        conn <- withConnection
        currentIssue <- findIssueById(editReq.id)(conn)
        _ <- isIssueEditable(currentIssue)(BadRequest)
        _ <- updateIssue(editReq.id, editReq.content)
      } yield Ok("ok")).run(Future.successful)
```

```scala
def withConnection(implicit ec: ExecutionContext): ActionCont[MyConnection] =
  ActionCont { f => // f は MyConnection => Future[Result] という継続
    val conn = new MyConnection()
    conn.open()
    try {
      f(conn) map { res =>
        if (is4xx(res) || is5xx(res)) { conn.rollback(); res }
        else { conn.commit(); res }
      }
    } finally {
      conn.close()
    }
  }
```

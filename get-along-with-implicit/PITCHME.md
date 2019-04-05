### implicit について

#### 2019-04-02

---

### implicit 種類

- implicit class
  - 拡張メソッド
- implicit parameter
  - 引き回すパラメータの省略
  - 型クラス
- implicit conversion
  - 存在を知っておけばいい

---

### implicit class

- 拡張メソッドを実現するための機能

```scala
implicit class RichInt(value: Int) {
  def factorial: Int = {
    def loop(x: Int, acc: Int): Int =
      if (x <= 0) acc
      else loop(x - 1, x * acc)
    loop(value, 1)
  }
}

```

```scala
scala> 5.factorial
120
```

---

### implicit paramter

- 引き回すパラメータの省略
- 型クラス

---

### 引き回すパラメータの省略

- 例. DB アクセスに使用するコネクション

```scala
// 例えばこんなリポジトリがあるとして
case class Person(name: String, age: Int)
case class MyConnection()
class MyRepository() {
  def findById(id: Long)(
    implicit ctx: MyConnection): Option[Person] = ???
  def create(entity: Person)(
    implicit ctx: MyConnection): Unit = ???
}
```

---

### 引き回すパラメータの省略

```scala
// without implicit
val repo = new MyRepository()
val conn: MyConnection = getConnection()
repo.findById(1L)(conn)
repo.create(Person("Alice", 21))(conn)
```

```scala
// with implicit
val repo = new MyRepository()
implicit val conn: MyConnection = getConnection()
repo.findById(1L)
repo.create(Person("Alice", 21))
```

---

### 引き回すパラメータの省略

- ちょくちょく使われている
- 利用パターンは割と限定されている
  - それゆえに初見に優しくない気はするが

---

### implicit paramter

- 引き回すパラメータの省略
- 型クラス

---

### scala.math.Ordering

- 型 A に対する大小関係を表現する
- compare の実装のみを提供すればいい
  - x > y なら 正の整数を返す
  - x == y なら 0 を返す
  - x < y なら 負の整数を返す

```scala
// 簡略化した定義
trait Ordering[T] {
  def compare(x: T, y: T): Int
}
```

---

### Ordering 定義例

```scala
case class Person(name: String, age: Int)

// age に基づく Ordering
val personAgeOrdering: Ordering[Person] =
  new Ordering[Person] {
    override def compare(x: Person, y: Person): Int =
      x.age.compareTo(y.age)
  }
```

---

### Ordering 使用例

```scala
val personAgeOrdering: Ordering[Person] = ... // 前 slide
val alice = Person("Alice", 21)
val bob = Person("Bob", 26)
val chris = Person("Chris", 20)
val people = Seq(alice, bob, chris)
```

```scala
// people から渡した Ordering に基づいて最大の Person を取得
// def max[B >: A](implicit cmp: Ordering[B]): A
scala> people.max(personAgeOrdering)
res1: Person = Person(Bob,26)
```

---

### 別の定義を使いたい場合

- 別の Ordering を提供すればいい

```scala
val personNameOrdering: Ordering[Person] =
  new Ordering[Person] {
    override def compare(x: Person, y: Person): Int =
      x.name.compareTo(y.name)
  }
```

```scala
// people から名前の辞書順で最大の Person を取得する
scala> people.max(personNameOrdering)
res0: Person = Person("Chris", 20)
```

---

### With implicit

- implicit 定義にすれば明示的に渡す必要はない
  - いわゆる型クラス的な使い方

```scala
scala> implicit val ordering: Ordering[Person] =
     |   personAgeOrdering
scala> people.max
res0: Person = Person(Bob,26)
```

---

### implicit が便利な場合 (私見?)

- 主要な定義が 1 通りになる場合
- ある型クラスの定義から更に別の型クラスを定義できる場合

```scala
// A, B に Ordering が定義されていれば (A, B) にも定義できる
implicit def orderingTuple2[A, B](
    implicit ordA: Ordering[A],
    ordB: Ordering[B]): Ordering[(A, B)] =
  new Ordering[(A, B)] {
    override def compare(x: (A, B), y: (A, B)): Int = {
      val res = ordA.compare(x._1, y._1)
      if (res != 0) res else ordB.compare(x._2, y._2)
    }
  }
```

```scala
scala> val peopleStringPair = Seq((alice, "3"), (alice, "2"), (alice, "1"))
scala> people.max // (Person(Alice,21),3)
```

---

### 継承によるアプローチとの比較

- scala.math.Ordered[A] も大小関係を表現
- こちらは型 A に継承させる必要がある

```scala
// 簡略化した定義
trait Ordered[A] extends Any with java.lang.Comparable[A] {
  def compare(that: A): Int
}
```

---

### 単純に使うと

- 単一の大小関係しか定義できない
- クラス定義元を触れないといけない

```scala
// age に基づく定義
case class Person(name: String, age: Int)
    extends Ordered[Person] {
  override def compare(that: Person): Int =
    age.compareTo(that.age)
}
```

```scala
// age に基づいて最大の Person を取得
// max を流用しているけど Ordered 用に定義すれば同じ話なので
scala> people.max
res0: Person = Person("Chris", 20)
```

---

### 回避策

- 専用の wrapper を用意してあげればいい

```scala
case class PersonForOrderedWithName(person: Person)
    extends Ordered[PersonForOrderedWithName] {
  override def compare(that: PersonForOrderedWithName): Int =
    person.name.compareTo(that.person.name)
}

case class PersonForOrderedWithAge(person: Person)
    extends Ordered[PersonForOrderedWithAge] {
  override def compare(that: PersonForOrderedWithAge): Int =
    person.age.compareTo(that.person.age)
}
```

```scala
// age に基づいて最大の Person を取得
scala> people.map(PersonForOrderedWithAge.apply).max.person
// name に基づいて最大の Person を取得
scala> people.map(PersonForOrderedWithName.apply).max.person
```

---

### 回避策

- Tuple2 に対する定義は多分こんな感じ
- 何がしたいか掴みづらいと思う

```scala
case class ToPairOrdered[A <: Ordered[A], B <: Ordered[B]](
    a: A, b: B) extends Ordered[ToPairOrdered[A, B]] {
  override def compare(that: ToPairOrdered[A, B]): Int = {
    // 省略
  }
}
```

```scala
// val pairs = Seq((alice, "3"), (alice, "2"), (alice, "1"))
scala> val pairMax = pairs.map {
     |   case (x, y) =>
     |     ToPairOrdered(PersonForOrderedWithName(x),
     |                   ToStringOrdered(y))
     | }.max
scala> (pairMax.a.person, pairMax.b.value) // (Person(Alice,21),3)
```

---

### implicit conversion

- 型 B が求められる箇所に (継承関係にない) 型 A の値を渡す
  - 通常型が合わずコンパイルエラー
- 型 A から型 B への暗黙の型変換定義があれば
  - 型チェックが通る。コンパイル時に変換処理が追加される (はず)

```scala
// 型 A から型 B への暗黙の型変換
implicit def fooConversion(x: A): B = ???
```

---

### 暗黙の型変換利用例

- play-json
  - 標準ライブラリの型を JsValue に変換

```scala
Json.obj(
  "name" -> "Alice", // String => JsValueWrapper の型変換
  "age" -> 20        // Int => JsValueWrapper の型変換
)
```

---

### 今は昔の JavaConversions

- 暗黙の型変換は積極的に使うべきではないという意見も
- 標準ライブラリでも JavaConversions が deprecated に

```scala
// with scala.collection.JavaConverters
import scala.collection.JavaConverters._
val javaList = new java.util.ArrayList[Int]
javaList.add(1)
val scalaList: mutable.Buffer[Int] = javaList.asScala
```

```scala
// with scala.collection.JavaConversions. this is deprecated
import scala.collection.JavaConversions._
val javaList = new java.util.ArrayList[Int]
javaList.add(1)
val scalaList: mutable.Buffer[Int] = javaList
```

---

### 今は昔の JavaConversions

- [JavaConversions の罠][1] としてこういうのが

```scala
import scala.collection.JavaConversions._
case class Foo(s: String)
val map: Map[Foo, String] =
  Map(
    Foo("a") -> "a",
    Foo("b") -> "b")

val v = map.get("a") // should be a type error, actually returns null
```

[1]: https://gist.github.com/xuwei-k/8870ea35c4bb6a4de05c

---

### 資料まとめ

- [README of tiqwab/slides/get-along-with-implicit][1]

[1]: https://github.com/tiqwab/slides/tree/master/get-along-with-implicit

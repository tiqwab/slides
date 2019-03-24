### implicit について

#### 2019-03-26

---

### implicit 種類

---

### implicit class

---

### implicit paramter

---

### 引き回すパラメータの省略

---

### 型クラスとして

- 操作による型の分類
  - 多分代数的な概念と相性がいいのはこれのおかげか？
- Strategy パターン的な
- アドホック多相の実現方法の 1 つ ([これ][1] や [これ][2] を読む感じ)
- [これ][2] の CONCEPT パターンを元に説明するのがわかりやすそう
- Ordered ではクラス定義自体を触れる必要があるし、クラスに 1 つしか定義できない

[1]: https://people.csail.mit.edu/dnj/teaching/6898/papers/wadler88.pdf
[2]: http://ropas.snu.ac.kr/~bruno/papers/TypeClasses.pdf

---

### 継承と型クラス

- 型クラスは操作による分類みたいな
- そもそも出自が違うので明確に分けれなくても当然かも？

---

### 型クラスのうれしみ

- implicit に渡さなくても明示的に渡しても別にいい
- ただコンパイル時に定義を導出できるのは強力

---

### scala.math.Ordering

- 型 A に対する大小関係を表現する
- 定義する側は compare の実装のみを提供すればいい
  - x > y なら 負, x == y なら 0, x < y なら 正の整数を返す

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

### ソート戦略を変えたい場合

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

- 別に専用の wrapper を用意してあげればいい

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
- 個人的にはわかりやすいが読みにくい

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
                         ToStringOrdered(y))
     | }.max
scala> (pairMax.a.person, pairMax.b.value) // (Person(Alice,21),3)
```

---

### implicit conversion

---

### 例. play-json

---

### 今は昔の JavaConversions

---

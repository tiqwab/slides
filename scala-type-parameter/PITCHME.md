## Scala の型パラメータ と抽象型メンバ

### 2019-07-09

---

### トピック

話すこと:

- 型パラメータについて
- 抽象型メンバについて
- 具体例を通して両者の比較

動機:

- 型パラメータと抽象型メンバの使い分けを自分なりに整理したかった

---

### 型パラメータ

- Java や C# におけるジェネリクスに相当するもの
- パラメトリック多相を提供するためのもの

```
# Java
class Foo<E>

# C#
class Foo<T>

# Scala
class Foo[E]
```

---

### 例. Stack

```scala
// MyStack クラスは型パラメータ A を取る
class MyStack[A] private (content: List[A]) {
  def push(a: A): MyStack[A] = new MyStack(a :: content)
  def pop(): (A, MyStack[A]) = content match {
    case Nil     => throw new NoSuchElementException("empty")
    case x :: xs => (x, new MyStack(xs))
  }
}

object MyStack {
  def apply[A](xs: A*): MyStack[A] = new MyStack(List(xs: _*))
}
```

```scala
scala> val s1: MyStack[Int] = MyStack()
scala> val s2: MyStack[String] = MyStack()
```

---

### 型パラメータの無い世界

```go
type Stack struct {
	content []interface{}
}

func (s *Stack) push(x interface{}) {
	s.content = append(s.content, x)
}

func (s *Stack) pop() interface{} {
	x := s.content[len(s.content)-1]
	s.content = s.content[:len(s.content)-1]
	return x
}

func main() {
	s := Stack{}
	s.push(1)
	x := s.pop().(int)
	fmt.Printf("x + 1 = %d\n", x + 1)
}
```

---

### 変位指定と上限下限境界

- 変位
  - 不変 (invariant)
  - 共変 (covariant)
  - 反変 (contravariant)
- 境界
  - 上限境界 (upper bounds)
  - 下限境界 (lower bounds)

---

### 不変

```scala
trait Animal
class Dog extends Animal
class Foo[A]
```

```scala
scala> val s1: Foo[Dog] = new Foo[Dog]()
```

---

### 共変 (1)

- B extends A ならば Foo[A] に Foo[B] が適合する
- `class Foo[+A]`
- (scala.Predef で import される) Seq, List は 共変

```scala
trait Animal { def walk(): Unit }
class Dog extends Animal { def walk(): Unit = ... }
```

```scala
scala> val ds: List[Dog] = List(new Dog(), new Dog())
scala> val as: List[Animal] = ds
scala> as.foreach(_.walk())
```

---

### 共変 (2)

- mutable なデータ構造は共変にはできない
- e.g. Java の配列

```java
class Sample1 {
    public static void main(String[] args) {
        Integer is[] = {1, 2, 3};
        Object os[] = is;
        os[1] = "foo";
        System.out.println(is[1]);
    }
}
```

```
$ java Sample1
Exception in thread "main" java.lang.ArrayStoreException: java.lang.String
        at Sample1.main(Sample1.java:5)
```

---

### 反変

- B extends A ならば Foo[B] に Foo[A] が適合する
- `class Foo[-A]`

```scala
scala> val s2: Foo[Dog] = new Foo[Animal]()
```

---

### 共変と反変の例 (1)

```scala
trait Function1[-A, +B] {
    def apply(v1: A): B
}
```

---

### 共変と反変の例 (2)

```scala
trait Animal
trait Mammalian extends Animal
class Dog extends Mammalian

class Transformer(f: Mammalian => Mammalian)
```

```scala
scala> val f1: Marmalian => Marmalian = ...
scala> val f2: Animal => Dog = ...
scala> val f3: Dog => Animal = ...

scala> new Transformer(f1)
scala> new Transformer(f2)
scala> new Transformer(f3) // compile error
```

---

### 変位指定とコンパイルエラー

- 変位指定に問題が無いかはコンパイラでチェックできる

```scala
class MyStack[+A] private (content: List[A]) {
  def push(a: A): MyStack[A] = new MyStack(a :: content)

  def pop(): (A, MyStack[A]) = content match {
    case Nil     => throw new NoSuchElementException("empty")
    case x :: xs => (x, new MyStack(xs))
  }
}
```

```
covariant type A occurs in contravariant position in type A of value a
     def push(a: A): MyStack[A] = new MyStack(a :: content)
              ^
```

---

### 上限境界

- MyStack に入るのは絶対に Animal、みたいなことができる

```scala
trait Animal
class Dog extends Animal

class MyStack[A <: Animal] private (content: List[A]) {
  ...
}

val s: MyStack[Dog] = MyStack()
// val s: MyStack[Int] = MyStack() // not compiled
```

---

### 下限境界

- 上限境界と逆の関係
- コレクション等でよく見る例

```scala
trait Animal
class Dog extends Animal
class Cat extends Animal

// パラメータ A を共変にする
class MyStack[+A] private (content: List[A]) {
  // 下限境界を設定する
  def push[A1 >: A](a: A1): MyStack[A1] = new MyStack(a :: content)
  ...
}
```

```scala
scala> val s1: MyStack[Dog] = MyStack()
scala> val s2 = s1.push(new Dog())
s2: MyStack[Dog] = ...
scala> val s3 = s2.push(new Cat())
s3: MyStack[Animal]
```

---

### 抽象型メンバ

- 最初見たとき型パラメータと似ている？ 使い分け？ と混乱した

```scala
trait Foo[A] {
    def bar(a: A): Unit = ()
}

trait Foo {
    type A
    def bar(a: A): Unit = ()
}
```

```scala
scala> val x1 = new Foo[Int]{}
x1: Foo1[Int] = ...
scala> x1.bar(0)

scala> val x2 = new Foo { type A = Int }
x2: Foo2{type A = Int} = ...
scala> x2.bar(0)
```

---

### Animal と Food の例 (1)

- コップ本にある例
- 牛は草しか食べないことにしたい

```scala
trait Food
trait Animal {
  def eat(a: Food): Unit
}

case class Grass() extends Food
case class Cow() extends Animal {
  // 牛は草しか食べないということを表現できていない
  override def eat(a: Food): Unit = ()
}

case class Fish() extends Food
```

```scala
scala> val cow: Cow = Cow()
scala> cow.eat(Grass())

// 魚を食べる牛
scala> val animal: Animal = cow
scala> cow.eat(Fish())
```

---

### Animal と Food の例 (2)

- コップ本にある例
- 牛は草しか食べないことにしたい

```scala
trait Food
trait Animal {
  def eat(a: Food): Unit
}

case class Grass() extends Food
case class Cow() extends Animal {
  // もし継承先で引数の型も派生型にできると...
  // (実際に Scala でコンパイルは通らない)
  override def eat(a: Grass): Unit = ()
}

case class Fish() extends Food
```

```scala
scala> val cow: Cow = Cow()
scala> cow.eat(Grass())
scala> cow.eat(Fish()) // compile error

// しかし Animal 型にキャストすれば魚を食べさせることは可能
scala> val animal: Animal = cow
scala> cow.eat(Fish())
```

---

### Animal と Food の例 (3)

- 型パラメータを使う

```scala
trait Food
trait Animal[A <: Food] {
  def eat(a: A): Unit = ()
}

case class Grass() extends Food
case class Cow() extends Animal[Grass]

case class Fish() extends Food
case class Whale() extends Animal[Fish]
```

```scala
scala> val cow: Cow = Cow()
scala> cow.eat(Grass())
scala> cow.eat(Fish()) // compile error

scala> val whale: Whale = Whale()
scala> whale.eat(Fish())
scala> whale.eat(Grass()) // compile error

scala> val animal: Animal[_] = cow
scala> animal.eat(Grass()) // compile error: required _$1
```

---

### Animal と Food の例 (4)

- 抽象型メンバを使う

```scala
trait Food
trait Animal {
  type SuitableFood <: Food
  def eat(a: SuitableFood): Unit = ()
}

case class Grass() extends Food
case class Cow() extends Animal {
  type SuitableFood = Grass
}

case class Fish() extends Food
case class Whale() extends Animal {
  type SuitableFood = Fish
}
```

```scala
scala> val cow: Cow = Cow()
scala> cow.eat(Grass())
scala> cow.eat(Fish()) // compile error

scala> val whale: Whale = Whale()
scala> whale.eat(Fish())
scala> whale.eat(Grass()) // compile error

scala> val animal: Animal = cow
scala> animal.eat(Grass()) // compile error: required animal.SuitableFood
```

---

### 仕様追加: Hunter 登場

- 型パラメータ

```scala
trait Animal[A <: Food] {
    ...
}

class Hunter[T <: Animal[_]] {
    def hunt(a: T): Unit = ()
}
```

- 抽象型メンバ

```scala
trait Animal {
    ...
}

class Hunter[T <: Animal] {
  def hunt(a: T): Unit = ()
}
```

---

### 仕様追加: Animal は Liquid を飲む

- 型パラメータ

```scala
trait Liquid

trait Animal[A <: Food, B <: Liquid] {
    ...
    def drink(b: B): Unit = ()
}

// Hunter のインタフェースにも影響がある
class Hunter[T <: Animal[_, _]] {
    def hunt(a: T): Unit = ()
}
```

- 抽象型メンバ

```scala
trait Animal {
    ...
    type SuitableLiquid
    def drink(b: SuitableLiquid): Unit = ()
}

// 変更はない
class Hunter[T <: Animal] {
  def hunt(a: T): Unit = ()
}
```

---

### 型パラメータと抽象型メンバ

- 型パラメータと抽象型メンバでできることは排他的ではない
- 目安として?
  - パラメトリック多相なデータ構造を定義したい
    - 型パラメータ
  - 継承先で型を再定義したい、型を隠蔽したい
    - 抽象型メンバ
    - 例えば [先日見た][2] のだと Entity が持つ ID の型を型メンバで持つべきだという議論が

---

### 資料まとめ

- [README of tiqwab/slides/scala-type-parameter][1]

[1]: https://github.com/tiqwab/slides/tree/master/scala-type-parameter
[2]: https://togetter.com/li/1325895

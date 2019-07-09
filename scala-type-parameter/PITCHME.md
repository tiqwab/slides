## Scala の型パラメータ

### 2019-07-09

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

val s1: Foo[Dog] = new Foo[Dog]()
// val s2: Foo[Animal] = new Foo[Dog]() // should be covariant
// val s2: Foo[Dog] = new Foo[Animal]() // should be contravariant
```

---

### 共変

- `class Foo[+A]`
- B extends A ならば Foo[A] に Foo[B] が適合する
- (scala.Predef で import される) Seq, List は 共変

---

### 共変

```scala
trait Animal { def walk(): Unit }
class Dog extends Animal { def walk(): Unit = ... }

val ds: List[Dog] = List(new Dog(), new Dog())
val as: List[Animal] = ds
as.foreach(_.walk())
```

---

### 共変

- mutable なデータ構造は共変にはできない
- e.g. `java.util.Array`

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

- `class Foo[-A]`
- B extends A ならば Foo[B] に Foo[A] が適合する

```scala
val s2: Foo[Dog] = new Foo[Animal]()
```

---

### 共変と反変の例 

```scala
trait Function1[-A, +B] {
    def apply(v1: A): B
}
```

---

### 共変と反変の例 

```scala
trait Animal
trait Mammalian extends Animal
class Dog extends Mammalian

class Transformer(f: Mammalian => Mammalian)

val f1: Marmalian => Marmalian = ...
val f2: Animal => Dog = ...
val f3: Dog => Animal = ...

new Transformer(f1)
new Transformer(f2)
// new Transformer(f3) // not compiled
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

### Set が共変ではない理由 (?)

---

### 上限境界

- MyStack との組み合わせ

### 下限境界

- MyStack との組み合わせ

### 抽象型メンバ

```scala
trait Foo[A] {
    def bar(a: A): Unit = ???
}

trait Foo {
    type A
    def bar(a: A): Unit = ???
}
```

### Animal と Food の例

- 普通にやるとコンパイルエラーか牛に魚を食べさせることになる

### Animal と Food の例

- コップ本の Animal の例を型パラメータで

### Animal と Food の例

- 抽象型メンバで

### 型パラメータと抽象型メンバ

- 型パラメータと抽象型メンバでできることは排他的ではない
- 目安として?
  - パラメトリック多相なデータ構造を定義したい
    - 型パラメータ
  - 継承先で型を再定義したい、型を隠蔽したい
    - 抽象型メンバ
    - 例えば最近見たのだと Entity が持つ ID の型を型メンバで持つべきだという議論が

### 資料まとめ

- [README of tiqwab/slides/scala-type-parameter][1]

[1]: https://github.com/tiqwab/slides/tree/master/scala-type-parameter

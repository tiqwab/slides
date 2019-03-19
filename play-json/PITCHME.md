## play-json について

### 2019-03-20

---

### play-json

- Scala 製 JSON ライブラリの一つ
- 現在は Play Framework からは独立したライブラリに

---

### play-json

- 何だか最初難しく感じる
  - 謎の記号?
  - implicit?
  - combinator あたり?

```scala
case class Person(name: String, age: Int)

val personReads: Reads[Person1] = (
  (JsPath \ "name").read[String] ~
    (JsPath \ "age").read[Int]
)((name, age) => Person1(name, age))

val json = Json.parse("""{"name": "Alice", "age": 21}""")
personReads.reads(json).get // Person(Alice,21)
```

---

### JSON ライブラリの要素

- JSON を表現するデータ型 (**JsValue**)
- JSON => オブジェクトの変換 (decoding,  **Reads**)
- オブジェクト => JSON の変換 (encoding, **Writes**)
- (文字列からのパーズ)
- (文字列化)

---

### JSON 構文

- [JSON - MDN][1]
- [RFC 8259][2]

```
JSON = null
    or true or false
    or JSONNumber // e.g. 123, 1.23
    or JSONString // e.g. "foo"
    or JSONObject // e.g. {"name": "Alice", "age": 21}
    or JSONArray  // e.g. [1, "foo", null]

...
```

[1]: https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/JSON
[2]: https://www.rfc-editor.org/rfc/rfc8259.txt

---

### JsValue

- play-json で JSON を表現する型
- 先程の JSON 構文に則った定義

```scala
sealed trait JsValue

case object JsNull extends JsValue
// 実際は JsBoolean を継承した JsTrue と JsFalse オブジェクトが存在
case class JsBoolean(value: Boolean) extends JsValue
case class JsString(value: String) extends JsValue
case class JsNumber(value: BigDecimal) extends JsValue
case class JsArray(value: IndexedSeq[JsValue]) extends JsValue
case class JsObject(value: Map[String, JsValue]) extends JsValue
```

---

### JsValue の作成

```scala
// {"name": "Alice", "age": 21} という JSON を表現
val sample: JsValue =
  JsObject(Map(
    "name" -> JsString("Alice"),
    "age" -> JsNumber(BigDecimal("21"))
  ))
```

```scala
// Json.obj: Seq[(String, JsValueWrapper)] => JsObject
// implicit conversion を利用して
val sample: JsValue =
  Json.obj(
    "name" -> "Alice",
    "age" -> 20
  )
```

---

### JsValue の作成と implicit

```scala
// name について明示的な変換にすると
val sample: JsValue =
  Json.obj(
    "name" -> toJsFieldJsValueWrapper("Alice")(StringWrites),
    "age" -> 20
  )
```

```scala
// in play.api.libs.json.Json
// 型 A に対して Writes が定義されていれば変換できる
implicit def toJsFieldJsValueWrapper[T](field: T)(
  implicit w: Writes[T]): JsValueWrapper = ...
```

---

### (余談) JsNumber は BigDecimal を持つ

- JSON 内の number をどう処理するか
- [RFC 88259][1]
  - どう処理するかは実装依存
- [ECMAScript の仕様][2]
  - IEEE754 倍精度浮動小数点数として扱う
- play-json
  - BigDecimal (任意精度の小数を表現する)

[1]: https://www.rfc-editor.org/rfc/rfc8259.txt
[2]: https://www.ecma-international.org/ecma-262/5.1/#sec-4.3.19

---

### (余談) JsNumber は BigDecimal を持つ

Google Chrome v72.0.3626.121:

```javascript
> Number.MAX_SAFE_INTEGER
9007199254740991
> JSON.stringify(9007199254740991)
"9007199254740991"
> JSON.stringify(9007199254740999)
"9007199254741000"
```

play-json v2.7.2 (with default settings):

```scala
scala> Json.stringify(JsNumber(9007199254740991L))
res7: String = 9007199254740991
scala> Json.stringify(JsNumber(9007199254740999L))
res8: String = 9007199254740999
```

---

### 文字列と JsValue の相互変換

String => JsValue

```scala
scala> val json = Json.parse("""{"name": "Alice", "age": 21}""")
res0: play.api.libs.json.JsValue = {"name":"Alice","age":21}
```

JsValue => String

```scala
scala> val str = Json.stringify(json)
res1: String = {"name":"Alice","age":21}
```

---

### Reads (decoding)

- JSON => 型 A の変換を定義する

```scala
case class Person(name: String, age: Int)

val personReads: Reads[Person1] = (
  (JsPath \ "name").read[String] ~
    (JsPath \ "age").read[Int]
)((name, age) => Person1(name, age)) // same as `Person1.apply _`

val json = Json.parse("""{"name": "Alice", "age": 21}""")
personReads.reads(json).get // Person(Alice,21)
```

- `(JsPath \ "name")`
- `(JsPath \ "name").read[String]`
- combinator (`~`)

---

### JsPath

```scala
val json = Json.parse("""{"name": "Alice", "age": 21}""")

// (JsPath \ "name") のような表記で JSON 上のパスを表現する
// JsResult は read の成功失敗を表せる型
scala> val path1: JsPath = JsPath \ "name"
path1.asSingleJsResult(sample1)
res0: JsResult[JsValue] = JsSuccess("Alice",)

scala> val path2: JsPath = JsPath \ "foo"
path2.asSingleJsResult(sample1) 
res1: JsResult[JsValue] = JsError(...)
```

---

### Reads[A]

```scala
// Reads[A] は `JsValue => JsResult[A]` という関数を表す
val stringReads: Reads[String] = Reads { json =>
  json match { // 冗長なパターンマッチだけどわかりやすく
    case JsString(string) => JsSuccess(string, JsPath())
    case _                => JsError("error")
  }
}
```

```scala
scala> stringReads.reads(JsString("foo"))
res2: JsResult[String] = JsSuccess(foo,)

scala> stringReads1.reads(JsNumber(1))
res3: JsResult[String] = JsError(...)
```

---

### JsPath#reads

- `(JsPath \ "name").read[String]`
  - JsPath: どこを読むか
  - Reads: どう読むか

```scala
scala> val json = Json.parse("""{"name": "Alice", "age": 21}""")

scala> val nameReads1: Reads[String] = (JsPath \ "name").read[String](stringReads1)
scala> nameReads1.reads(json)
res0: JsResult[String] = JsSuccess(Alice,/name)

// あるいは stringReads1 は implicit parameter として渡せる
scala> implicit val stringReads2 = stringReads1
scala> val nameReads2: Reads[String] = (JsPath \ "name").read[String]
res1: JsResult[String] = JsSuccess(Alice,/name)
```

---

### Reads コンビネータ

```scala
scala> case class Person(name: String, age: Int)

scala> val personReads: Reads[Person1] = (
     |   (JsPath \ "name").read[String] ~
     |     (JsPath \ "age").read[Int]
     | )((name, age) => Person1(name, age))

scala> val json = Json.parse("""{"name": "Alice", "age": 21}""")

scala> personReads.reads(json)
res2: JsResult[Person] = JsSuccess(Person(Alice,21),)
```

---

### Reads コンビネータ

```scala
// 1 Reads だけ受け取る以下のようなクラスを考えると
case class ReadsCombinator1[A](ra: Reads[A]) {
  def apply[B](f: A => B): Reads[B] = Reads { json =>
    ra.reads(json) match {
      case JsSuccess(a, _) =>
        JsSuccess(f(a))
      case _ =>
        JsError("error")
    }
  }
}
```

```scala
val nameReads: Reads[String] = ReadsCombinator1(
  (JsPath \ "name").read[String]
)(name => name)
```

---

### Reads コンビネータ

```scala
// 1 Reads だけ受け取る以下のようなクラスを考えると
case class ReadsCombinator1[A](ra: Reads[A]) {
  def apply[B](f: A => B): Reads[B] = ...
  def ~[B](rb: Reads[B]): ReadsCombinator2[A, B] =
    ReadsCombinator2(ra, rb)
}

case class ReadsCombinator2[A, B](ra: Reads[A], rb: Reads[B]) {
  def apply[C](f: (A, B) => C): Reads[C] = ...
  def ~[C](rc: Reads[C]): ReadsCombinator3[A, B, C] =
    ReadsCombinator3(ra, rb, rc)
}
```

```scala
val personReads: Reads[Person1] = (
  ReadsCombinator1((JsPath \ "name").read[String]) ~
    (JsPath \ "age").read[Int]
)((name, age) => Person1(name, age))
```

---

### Reads コンビネータ

- イメージ的にはこんな感じの作成
  - 22 引数を取るクラスまで存在する
- 最初の ReadsCombinator1 を作成する部分は implicit 頼り
- 実際はコンビネータは Writes, Format と共通化されている

---

### Writes (encoding)

- `A => JsValue` を表現する

```scala
val personWrites: Writes[Person] = (
  (JsPath \ "name").write[String] ~
    (JsPath \ "age").write[Int]
)(person => (person.name, person.age))

scala> val person = Person("Alice", 21)
scala> personWrites.writes(person)
res1: JsValue = {"name":"Alice","age":21}
```

---

### case class への自動導出

- マクロで簡潔に書ける

```scala
case class Person(name: String, age: Int)
val personReads: Reads[Person] = Json.reads[Person]
val personWrites: Writes[Person] = Json.writes[Person]
```

---

### 資料まとめ

- [README of tiqwab/slides/play-json][1]

[1]: https://github.com/tiqwab/slides/tree/master/play-json

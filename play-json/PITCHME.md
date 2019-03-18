## play-json について

### 2019-03-20

---

### play-json

- Scala 製 JSON ライブラリの一つ
  - 最新バージョンは 2.7.2 (2019-03-20 現在)
  - 現在のサービスでは 2.6.10 を使用
- 2.6 以降 Play Framework からは独立
- とはいえ Play Framework との組み合わせで使われることが多いはず

---

### play-json

- 何だか最初難しく感じる
  - combinator あたり?
  - 謎の記号?
  - implicit?

```scala
case class Person(name: String, age: Int)

val personReads: Reads[Person1] = (
  (JsPath \ "name").read[String] ~
    (JsPath \ "age").read[Int]
)((name, age) => Person1(name, age)) // same as `Person1.apply _`

val json = Json.parse("""{"name": "Alice", "age": 21}""")
personReads.reads(json).get // Person(Alice,21)
```

---

### JSON 構文

- [JSON - MDN][1]
- [RFC 8259][2]

```
JSON = null
    or true or false
    or JSONNumber
    or JSONString
    or JSONObject
    or JSONArray

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

### (余談) JsNumber は BigDecimal を持つ

- JSON 内の number をどう処理するか
- [RFC 88259][1]
  - どう処理するかは実装依存
  - IEEE754 倍精度浮動小数点数として扱うのが無難
- [ECMAScript の仕様][2]
  - IEEE754 倍精度浮動小数点数 として扱う
- play-json
  - BigDecimal (任意精度の小数を表現するクラス)

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
scala> val str = Json.stringify(json2)
res1: String = {"name":"Alice","age":21}
```

---

### JsValue の作成

冗長な作成

```scala
val sample1: JsValue =
  Json.obj(
    "name" -> JsString("Alice"),
    "age" -> JsNumber(BigDecimal("20"))
  )
```

---

### JsValue の作成

直感的な作成

```scala
val sample: JsValue =
  Json.obj(
    "name" -> "Alice",
    "age" -> 20
  )
```

---

### JsValue の作成

by implicit conversion
(イメージ。ライブラリの実際の定義とは異なる)

```scala
import scala.languageFeature.implicitConversions

implicit def stringToJsString(value: String): JsValue =
  JsString(value)

implicit def intToJsNumber(value: Int): JsValue =
  JsNumber(BigDecimal(value))
```

```scala
val sample: JsValue =
  Json.obj(
    "name" -> stringToJsString("Alice"),
    "age" -> intToJsNumber(20)
  )
```

---

### Reads (Unmarshal)

---

### Writes (Marshal)

---

### 資料まとめ

- [README of tiqwab/slides/play-json][1]

[1]: https://github.com/tiqwab/slides/tree/master/play-json

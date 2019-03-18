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

[1]: https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/JSON
[2]: https://www.rfc-editor.org/rfc/rfc8259.txt

```
JSON = null
    or true or false
    or JSONNumber
    or JSONString
    or JSONObject
    or JSONArray

... (以下略)
```

---

### 資料まとめ

- [README of tiqwab/slides/play-json][1]

[1]: https://github.com/tiqwab/slides/tree/master/play-json

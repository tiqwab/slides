### Topic

- [ScalaJson - 2.7.x][1]
  - JsValue
  - Json
    - utility methods
      - parse, stringify
  - JsPath
    - traverse json structure
- [ScalaJsonCombinators - 2.7.x][2]
  - 過去の自分のログを読むとやはりここが詰まりどころだったと思う
- [ScalaJsonAutomated - 2.7.x][3]

いまサービスで使用している play-json のバージョンは？

- JSON の構文
- JSON を表現するデータ型
  - JsValue
  - number についての余談
- 文字列との JsValue 変換
  - Json.parse, Json.stringify
- プログラムによる JsValue 作成
  - 例
  - 冗長に書く
  - implicit 定義の解説
- Unmarshal (obj to json, Reads)
  - Reads の定義
  - combinator 雰囲気理解
  - macro による case class への定義
- Marshal (json to obj, Writes)
  - Writes の定義
- Format
- (他ライブラリ)

### JsValue

#### JSON 構文 (ref. [JSON - MDN][4])

```
JSON = null
    or true or false
    or JSONNumber
    or JSONString
    or JSONObject
    or JSONArray

... (以下略)
```

- number は何で表現している？
  - BigDecimal
  - JSONNumber としては (ざっくりいえば) 表記として数値なら問題ない
  - プログラムでどうパースするかは言語やライブラリの実装依存になる (はず)
    - [RFC 8259][6] では
      > This specification allows implementations to set limits on the range and precision of numbers accepted...
      といい、同時に
      > Since software that implements IEEE 754 binary64 (double precision) numbers [IEEE754] is generally available and widely used, good interoperability can be achieved by implementations that expect no more precision or range than these provide...
      と言っているので、まあ IEEE 754 倍精度小数点数が無難みたいな
    - JavaScript は IEEE 754 の倍精度浮動小数点数として扱う
      - [ECMAScript の仕様][5]
    - play-json の場合 BigDecimal として扱う
      - 精度等を設定値として渡せる
  - 余談として ID 値を number で扱っていてずれた話をしてもいいかもね

#### JsValue の作成

- 冗長な作成
- implicit conversion

### Json utility methods

- parse, stringify
  - [Jackson][7] を使用

### JsLookup

- skip してもいいかな

### モデルとのマッピング

- play-json がはじめ馴染みにくい仮説
  - モデルとのマッピングをアノテーションなんかで表現する経験しかない
  - 成功失敗を表す代数的データ型のハンドリング
  - 謎の記号
  - implicit

jackson
python
go
haskell

[1]: https://www.playframework.com/documentation/2.7.x/ScalaJson
[2]: https://www.playframework.com/documentation/2.7.x/ScalaJsonCombinators
[3]: https://www.playframework.com/documentation/2.7.x/ScalaJsonAutomated
[4]: https://developer.mozilla.org/ja/docs/Web/JavaScript/Reference/Global_Objects/JSON
[5]: https://www.ecma-international.org/ecma-262/5.1/#sec-4.3.19
[6]: https://www.rfc-editor.org/rfc/rfc8259.txt
[7]: https://github.com/FasterXML/jackson

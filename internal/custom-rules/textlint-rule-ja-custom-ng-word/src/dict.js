export default [
    /*
    [ {
        word_id: 509800,          // 辞書内での単語ID
        word_type: 'KNOWN',       // 単語タイプ(辞書に登録されている単語ならKNOWN, 未知語ならUNKNOWN)
        word_position: 1,         // 単語の開始位置
        surface_form: '黒文字',    // 表層形
        pos: '名詞',               // 品詞
        pos_detail_1: '一般',      // 品詞細分類1
        pos_detail_2: '*',        // 品詞細分類2
        pos_detail_3: '*',        // 品詞細分類3
        conjugated_type: '*',     // 活用型
        conjugated_form: '*',     // 活用形
        basic_form: '黒文字',      // 基本形
        reading: 'クロモジ',       // 読み
        pronunciation: 'クロモジ'  // 発音
      } ]
    */
    {
        "message": `禁句: "かも" が使われています`,
        "tokens": [
            {
                "surface_form": "かも",
                "pos": "助詞",
            },
            {
                "surface_form": "．",
                "pos": "記号",
                "pos_detail_1": "句点",
            }
        ]
    },
    {
        "message": `禁句: "かも" が使われています`,
        "tokens": [
            {
                "surface_form": "かも",
                "pos": "助詞",
            },
            {
                "surface_form": "しれ",
                "pos": "動詞",
            }
        ]

    },
    {
        "message": `禁句: "だから" が使われています`,
        "tokens": [
            {
                "surface_form": "だ",
            },
            {
                "surface_form": "から"
            }
        ]
    },
    {
        "message": `禁句: "つまり" が使われています`,
        "tokens": [
            {
                "surface_form": "つまり",
                "pos": "接続詞"
            }
        ]
    },
    {
        "message": `禁句: "そして" が使われています`,
        "tokens": [
            {
                "surface_form": "そして",
                "pos": "接続詞"
            }
        ]
    },
    {
        "message": `禁句: "だが" が使われています`,
        "tokens": [
            {
                "surface_form": "だ",
            },
            {
                "surface_form": "が"
            }
        ]
    },
    {
        "message": `禁句: "したら" が使われています`,
        "tokens": [
            {
                "surface_form": "し",
            },
            {
                "surface_form": "たら"
            }
        ]
    },
    {
        "message": `"研究"は長期継続される一連の活動を意味するため，使用することは希です`,
        "tokens": [
            {
                "surface_form": "本",
            },
            {
                "surface_form": "研究"
            }
        ]
    },
    {
        "message": `"研究"は長期継続される一連の活動を意味するため，使用することは希です`,
        "tokens": [
            {
                "surface_form": "研究",
            },
            {
                "surface_form": "を"
            },
        ]
    },
];
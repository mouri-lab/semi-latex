// LICENSE : MIT
"use strict";
import TextLintTester from "textlint-tester";
import rule from "../src/textlint-rule-ja-custom-ng-word";

const tester = new TextLintTester();
// ruleName, rule, { valid, invalid }
tester.run("textlint-rule-rule-custom-ng-word", rule, {
    valid: [
        "コレは弱くない",
        "これは弱くないと思われますがどうですか?",
        "どう工夫したのかも書いてみてください",
        "カモシカ",
        "カモネギ",
        "しかも",
        "トイレのつまりが取れない",
        "太郎らの研究では",
    ],
    invalid: [
        // single match
        {
            text: "問題があるかも．",
            errors: [
                {
                    message: `禁句: "かも" が使われています`,
                    line: 1,
                    column: 6 //"かも"はtextの6文字目
                }
            ]
        },
        {
            text: "私は弱いかもしれない．",
            errors: [
                {
                    message: `禁句: "かも" が使われています`,
                    line: 1,
                    column: 5
                }
            ]
        },
        {
            text: "猫は動物だから動く",
            errors: [
                {
                    message: `禁句: "だから" が使われています`,
                    line: 1,
                    column: 5
                }
            ]
        },
        {
            text: "つまりすごい",
            errors: [
                {
                    message: `禁句: "つまり" が使われています`,
                    line: 1,
                    column: 1
                }
            ]
        },
        {
            text: "そしてなくなった",
            errors: [
                {
                    message: `禁句: "そして" が使われています`,
                    line: 1,
                    column: 1
                }
            ]
        },
        {
            text: "猫は動物だが植物でもある",
            errors: [
                {
                    message: `禁句: "だが" が使われています`,
                    line: 1,
                    column: 5
                }
            ]
        },
        {
            text: "提出したら弾かれた",
            errors: [
                {
                    message: `禁句: "したら" が使われています`,
                    line: 1,
                    column: 3
                }
            ]
        },
        {
            text: "本研究では",
            errors: [
                {
                    message: `"研究"は長期継続される一連の活動を意味するため，使用することは希です`,
                    line: 1,
                    column: 1
                }
            ]
        },
        {
            text: "研究を行った",
            errors: [
                {
                    message: `"研究"は長期継続される一連の活動を意味するため，使用することは希です`,
                    line: 1,
                    column: 1
                }
            ]
        },
    ],
});
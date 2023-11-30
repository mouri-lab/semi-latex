# !/bin/env python3
import os
import sys


def find_newest_tex_file(directory):
    tex_files = [
        os.path.join(root, f)
        for root, dirs, files in os.walk(directory)
        for f in files
        if f.endswith(".tex")
    ]

    if not tex_files:
        print("ディレクトリ内にTexファイルが見つかりませんでした。")
        return None

    newest_file = max(tex_files, key=os.path.getmtime)

    return newest_file


# コマンドライン引数からディレクトリのパスを取得
if len(sys.argv) != 2:
    print("正しい引数が指定されていません。プログラムの実行時にディレクトリパスを指定してください。")
    sys.exit(1)

directory_path = sys.argv[1]

if not os.path.exists(directory_path):
    print("指定されたディレクトリが存在しません。")
else:
    newest_tex_file = find_newest_tex_file(directory_path)

    if newest_tex_file:
        print(f"{newest_tex_file}")
    else:
        exit(1)

# !/bin/env python3
import os
import sys
import re


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

    return  max(tex_files, key=os.path.getmtime)



# \include{cover}
def search_main_file_path(dir_path:str, target_file:str):
    tex_files = [
        os.path.join(root, f)
        for root, dirs, files in os.walk(dir_path)
        for f in files
        if f.endswith(".tex")
    ]
    target_file_no_extexsion = os.path.splitext(os.path.basename(target_file))[0]
    search_query = "\\include{" + target_file_no_extexsion+ "}"
    for tex_path in tex_files:
        if not is_main(tex_path):
            continue

        tex_texts = open(tex_path,"r",encoding="utf-8").readlines()
        for line_text in tex_texts:
            if line_text.find(search_query) < 0:
                continue
            if line_text.find('%') < 0:
                return tex_path

            if line_text.find(search_query) < line_text.find('%'):
                return tex_path

        return None

def is_main(tex_file_path:str):
    tex_texts = open(tex_file_path,"r",encoding="utf-8").readlines()
    for line_text in tex_texts:
        if line_text.find('\\documentclass[') < 0:
            continue
        if line_text.find('%') < 0:
            return True

        if line_text.find('\\documentclass[') < line_text.find('%'):
            return True
    return False

def main():
    # コマンドライン引数からディレクトリのパスを取得
    if len(sys.argv) < 2:
        print("正しい引数が指定されていません。プログラムの実行時にディレクトリパスを指定してください。")
        sys.exit(1)

    directory_path = sys.argv[1]

    if not os.path.exists(directory_path):
        print("指定されたディレクトリが存在しません。")
        sys.exit(1)

    if len(sys.argv) != 3:
        newest_tex_path = find_newest_tex_file(directory_path)
    else:
        newest_tex_path = sys.argv[2]


    if is_main(newest_tex_path):
        print(newest_tex_path)
        return

    target_dir_path = os.path.dirname(newest_tex_path)
    main_tex_path = search_main_file_path(target_dir_path, newest_tex_path)
    if main_tex_path != None:
        print(main_tex_path)
    else:
        print("インクルード元のファイルを発見できませんでした")
        sys.exit(1)

    return


if __name__ == '__main__':
    sys.exit(main())


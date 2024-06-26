# !/bin/env python3
import os
import sys


def ERROR(comment: str):
    print(f"[ERROR] {comment}", flush=True)
    exit(0)


def find_newest_tex_file(directory):
    tex_files = [
        os.path.join(root, f)
        for root, dirs, files in os.walk(directory)
        for f in files
        if f.endswith(".tex")
    ]

    if not tex_files:
        ERROR(f"ディレクトリ({directory})にTexファイルが見つかりませんでした。")

    return max(tex_files, key=os.path.getmtime)


# \include{cover}
def search_main_file_path(dir_path: str, target_file: str):
    tex_files = [
        os.path.join(root, f)
        for root, dirs, files in os.walk(dir_path)
        for f in files
        if f.endswith(".tex")
    ]
    target_file_no_extexsion = os.path.splitext(os.path.basename(target_file))[0]
    search_query = "\\include{" + target_file_no_extexsion + "}"
    for tex_path in tex_files:
        if not is_main(tex_path):
            continue

        tex_texts = open(tex_path, "r", encoding="utf-8").readlines()
        for line_text in tex_texts:
            if line_text.find(search_query) < 0:
                continue
            if line_text.find("%") < 0:
                return tex_path

            if line_text.find(search_query) < line_text.find("%"):
                return tex_path

        return None


def is_main(tex_file_path: str):
    tex_texts = open(tex_file_path, "r", encoding="utf-8").readlines()
    for line_text in tex_texts:
        if line_text.find("\\documentclass") < 0:
            continue
        if line_text.find("%") < 0:
            return True

        if line_text.find("\\documentclass") < line_text.find("%"):
            return True
    return False


def main():
    # コマンドライン引数からディレクトリのパスを取得
    if len(sys.argv) < 3:
        ERROR(
            "正しい引数が指定されていません。プログラムの実行時にディレクトリパスを指定してください。"
        )

    CONTAINER_HOME_PATH = sys.argv[1]
    WORK_DIR_PATH = sys.argv[2]

    if not os.path.exists(WORK_DIR_PATH):
        ERROR(f"指定されたディレクトリが存在しません: {WORK_DIR_PATH}")

    if len(sys.argv) < 4:
        # semi-latex内で最新のtexファイルを取得
        newest_tex_path = find_newest_tex_file(WORK_DIR_PATH)
    else:
        # 絶対パスとsemi-latex内の相対パスに対応
        input_path: str = sys.argv[3]

        # 絶対パスと相対パスに対応
        if os.path.exists(CONTAINER_HOME_PATH + input_path):
            newest_tex_path = CONTAINER_HOME_PATH + input_path
        elif os.path.exists(WORK_DIR_PATH + "/" + input_path):
            newest_tex_path = WORK_DIR_PATH + "/" + input_path
        else:
            ERROR(f"指定されたpath({input_path})が不正です")

        if not os.path.exists(newest_tex_path):
            ERROR(f"指定されたパスが存在しません: {input_path}")

        if os.path.isfile(input_path):
            if os.path.splitext(input_path)[-1] != ".tex":
                ERROR(f"tex以外のファイルが指定されています: f{input_path}")

        elif os.path.isdir(newest_tex_path):
            newest_tex_path = find_newest_tex_file(newest_tex_path)


    if is_main(newest_tex_path):
        print(newest_tex_path.replace(CONTAINER_HOME_PATH, ""))
        return None

    target_dir_path = os.path.dirname(newest_tex_path)
    main_tex_path = search_main_file_path(target_dir_path, newest_tex_path)
    if main_tex_path != None:
        print(main_tex_path.replace(CONTAINER_HOME_PATH, ""))
    else:
        ERROR("インクルード元のファイルを発見できませんでした")

    return


if __name__ == "__main__":
    main()

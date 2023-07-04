# dqm_installer_flt

DQM Installer (Flutterリメイク)

## ダウンロード

[Releases](https://github.com/chika3742/dqm_installer_flt/releases)

### 動作確認OS

| プラットフォーム | バージョン |
| --- | --- |
| Windows | Windows 11 22H2 build 22623.1180 |
| macOS | macOS Ventura 13.1 (MBP 2020 M1*) |
| Linux | Ubuntu 22.10 |

- Apple Mシリーズを搭載したMacでは色の表示に不具合が発生します。詳しくは以下をご覧ください。
- macOS版はIntel/Apple Silicon(Apple Mシリーズ)両対応です。

## 利用上の注意

Windows 版 Minectaft ランチャーには、7/8版と10/11版(Microsoft Store版)が存在します。インストール時に使用する、ランチャーのアカウントデータ(ユーザー名など)は7/8版と10/11版で別のファイルに保存されており、本ソフトでは10/11版のデータが優先されます。

同じPCに両方がインストールされていると意図しない挙動が発生する可能性があるため、本ソフトを使用する前に必ず7/8版のランチャーをアンインストールしてください。

## Apple Silicon Macでの表示の修正

M1シリーズを搭載したMacでMinecraft 1.5.2を起動すると、光の三原色であるRGBのうち青と赤が逆転して表示されてしまいます。また、フルスクリーンにするとMinecraftがクラッシュするという問題も抱えています。以下の方法で修正可能です。

1. 通常通り公式のランチャーを用いてインストールします。
2. [Prism Launcher](https://prismlauncher.org/download/mac/)をインストールし、起動します。
3. 「起動構成を追加」をクリックし、「名前」を「__DQM__」、「バージョン」で「1.5.2」を選択し、保存します。
4. 作成した構成を右クリックし、「編集」をクリックします。
5. 「バージョン」タブ→「Miencraft jarを置き換え」をクリックし、`~/Library/Application Support/minecraft/versions/DQMV vX.XX/DQMV vX.XX.jar`を選択します。[辿り着く方法はこちら](#minecraftディレクトリにたどり着けない場合)
6. 「設定」タブ→「Javaの指定」にチェック→「自動検出」より、「バージョン」が`1.8.x_xxx`のものを選択します。無い場合は、[こちらのページ](https://www.azul.com/downloads/?version=java-8-lts&os=macos&package=jdk#zulu)よりZulu OpenJDKをダウンロードしてインストールしてから選択してください。
7. Spotlight検索等でターミナルを起動し、以下のコマンドを実行します。

    ```bash
    rm -rf ~/Library/Application\ Support/PrismLauncher/instances/DQM/.minecraft
    ln -s ~/Library/Application\ Support/minecraft ~/Library/Application\ Support/PrismLauncher/instances/DQM/.minecraft
    ```
8. 作成した構成をダブルクリックして起動します。
9. ビデオ設定でフルスクリーンをオンにします。

ウィンドウモード時は色がおかしいままですが、フルスクリーンにすることで直ります。

### minecraftディレクトリにたどり着けない場合

- Finder→「表示」→「表示オプションを表示」で、「"ライブラリ"フォルダーの表示」にチェックが入っていることを確認
- 「Finder」→「設定」→「サイドバー」において、家アイコンに自身のユーザー名が書かれたチェックボックスにチェックが入っていることを確認
- 「Miencraft jarを置き換え」をクリックし、(サイドバーにある自身のユーザー名)→Library→Application Support→minecraft→versions→DQMV vX.XX→DQMV vX.XX.jar と辿ってください。

## 利用方法

今後記事を投稿予定です。

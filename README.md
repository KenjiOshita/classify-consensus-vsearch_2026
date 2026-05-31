# classify-consensus-vsearch_2026

このリポジトリは、メタバーコーディング解析で得られた配列データに対し、QIIME 2の公式プラグイン（classify-consensus-vsearch）とSILVAデータベースを用いて系統分類を自動で行い、最終的にASVテーブル（CSV形式）を出力する手順をまとめたものです。BLASTよりも高速に系統分類を実行できる方法です。RAMが16GB以上あるPCの場合は、機械学習などより高度なアルゴリズムを用いた系統分類が可能であり、本解析方法はそのような解析ができないが、系統分類を自動化したい場合に適しています。注意：これらの解析はWindowsでLinuxが使える状態で実施可能です。Linuxをダウンロード済みのPCで実行してください。  
原著論文：Torbjørn Rognes, Tomáš Flouri, Ben Nichols, Christopher Quince, and Frédéric Mahé. Vsearch: a versatile open source tool for metagenomics. PeerJ, 4:e2584, 2016. doi:10.7717/peerj.2584.

---

## フォルダ構成（推奨）

解析データを整理するため、ホームディレクトリに専用のフォルダ構造を作成します。
以下の構成になるようにファイルを配置してください。

```
Taxonomic_analysis/
├── scripts/       # 解析に使用するスクリプトを保存
│   ├── run_qiime2_vsearch.sh
│   └── convert_to_csv_split.py
├── database/      # SILVAなどのデータベースを保存
└── analysis/
    └── HIroshimabay_2025_18S/  # 生物技研から提供されたファイル「repset.qza」「table.qza」をここに入れる
        ├── repset.qza   # キメラ除去済みのASV代表配列
        ├── table.qza    # ASVのカウント表
        ├── convert.txt  # サンプル情報（メタデータ）
        └── map.txt      # サンプル情報（メタデータ）
```

---

## １．解析の準備（初回のみ）

### １－１．Minicondaのインストール

「Miniconda」をインストール（Linuxで実行）します。ホームディレクトリで作業します。

```bash
# ホームディレクトリへ移動
cd ~
# Linux用のMinicondaインストーラーをダウンロード
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
# インストーラーを実行
bash Miniconda3-latest-Linux-x86_64.sh
```

**【インストール中の進め方】** Enter キーを押し、ライセンス条項をスクロールして確認。Do you accept the license terms? [yes|no] → yes と入力して Enter。Press ENTER to confirm the location → そのまま Enter。by running conda init? → yes と入力して Enter。

**【設定の反映】** インストール完了後、以下のコマンドで設定を有効化します。

```bash
source ~/.bashrc
```

これで、画面の左側に再び (base) が表示されれば、Linux版Minicondaのインストール完了です。以下のコマンドでバージョンが出るかを確認します。

```bash
conda -V
```

### １－２．QIIME 2 のダウンロード（mambaによる安定版構築）

QIIME 2はデータが重く、標準の conda ではエラーが出やすいため、高速化ツール mamba を使用して安定版（2025.10）をインストールします。

```bash
# 高速化ツール「mamba」の導入
conda install -n base -c conda-forge mamba -y

# QIIME 2（2025.10）の設計図をダウンロード
wget https://raw.githubusercontent.com/qiime2/distributions/refs/heads/dev/2025.10/amplicon/released/qiime2-amplicon-ubuntu-latest-conda.yml

# mamba を使って環境構築（インストール）を実行
mamba env create --name qiime2-amplicon-2025.10 --file qiime2-amplicon-ubuntu-latest-conda.yml

# 不要になった設定ファイルを削除
rm qiime2-amplicon-ubuntu-latest-conda.yml
```

### １－３．データベースのダウンロード（初回のみ）

VSEARCHコンセンサス法では「配列」と「分類名」の2つのファイルを使用します。公式のSILVA 138データベースをダウンロードします。

```bash
# databaseフォルダに移動
cd ~/work/Taxonomic_analysis/database

# SILVA 138の代表配列（seqs）と分類名（tax）をダウンロード
wget https://data.qiime2.org/2024.10/common/silva-138-99-seqs.qza
wget https://data.qiime2.org/2024.10/common/silva-138-99-tax.qza
```

---

## ２．解析の実行 / 2. Running the Analysis

### ２－１．準備：QIIME 2の起動とフォルダへの移動 / 2-1. Setup: Activating QIIME 2 and Moving to the Working Directory

WSL（Ubuntu）を起動し、以下のコマンドでQIIME 2環境を有効化してから、作業フォルダへ移動します。  
Launch WSL (Ubuntu) and activate the QIIME 2 environment with the commands below, then move to the working directory.

```bash
# QIIME 2環境の有効化 / Activate QIIME 2 environment
# 左側の文字が (base) から (qiime2-amplicon-2025.10) に変われば完了
# The prompt changes from (base) to (qiime2-amplicon-2025.10) when done
conda activate qiime2-amplicon-2025.10

# 作業ディレクトリへ移動 / Move to working directory
cd ~/work/Taxonomic_analysis
```

### ２－２．一括解析スクリプトの実行 / 2-2. Running the Analysis Script

一致率97%（0.97）の閾値でコンセンサス分類とカウント表と系統分類の結合を自動で実行します。条件は、後の解析で使用したいデータの分類階級ごとに変更してください。  
The script automatically runs consensus classification at a 97% identity threshold and merges the count table with taxonomy results. Adjust parameters as needed for your target taxonomic level.

```bash
# 解析の実行（一番最後の解析フォルダ名「HIroshimabay_2025_18S」を適宜変更すること）
# Run analysis (change the last argument to your own analysis folder name)
bash scripts/run_qiime2_vsearch.sh analysis/HIroshimabay_2025_18S
```

**【主要パラメータの説明 / Key Parameters】**

| パラメータ / Parameter | 設定値 / Value | 説明 / Description |
|---|---|---|
| `--p-perc-identity` | 0.97 | 参照配列との最低一致率（97%） / Minimum identity against reference sequences (97%) |
| `--p-query-cov` | 0.80 | クエリ配列のカバレッジ（80%以上） / Minimum query coverage (80%) |
| `--p-maxaccepts` | 10 | ヒットとして受け入れる最大候補数 / Maximum number of hits to accept |
| `--p-min-consensus` | 0.51 | コンセンサス分類の最低合意率（51%） / Minimum fraction of assignments to reach consensus (51%) |
| `--p-threads` | 40 | 使用するCPUスレッド数 / Number of CPU threads to use |

---

## ３．出力結果とグラフの確認方法 / 3. Output Files and Visualization

解析が完了すると、指定したフォルダ内に以下のファイルが作成されます。  
After the analysis completes, the following files will be created in the specified folder.

### ① R解析・Excel閲覧用データ / Data for R or Excel

- **`asv_counts.tsv`** — ASVのカウント表をTSV形式に変換したファイル。ExcelやRで開いて利用できます。  
  ASV count table converted to TSV format. Can be opened in Excel or R.
- **`exported-taxonomy/taxonomy.tsv`** — 各ASVの系統分類結果。  
  Taxonomic classification results for each ASV.

### ② 系統組成棒グラフの確認（taxa-bar-plots.qzv）/ Taxonomic Bar Plot (taxa-bar-plots.qzv)

サンプルごとの生物の割合を示す棒グラフを作成します。作成された拡張子 .qzv のファイルは、専用のWebサイトで閲覧します。  
A bar plot showing the taxonomic composition per sample is generated. The `.qzv` file can be viewed on the QIIME 2 View website.

1. Windows側のエクスプローラーで作業フォルダを開きます。  
   Open the working folder in Windows Explorer.
2. ブラウザで [QIIME 2 View](https://view.qiime2.org) にアクセスします。  
   Open [QIIME 2 View](https://view.qiime2.org) in your browser.
3. 確認したいファイル（`taxa-bar-plots.qzv` など）をブラウザの画面上にドラッグ＆ドロップします。  
   Drag and drop the `.qzv` file (e.g., `taxa-bar-plots.qzv`) onto the browser window.

**【グラフの操作方法 / How to Use the Plot】**

- **Taxonomic Level:** グラフ上部のメニューからレベルを変更することで、門(Phylum)・綱(Class)など分類の解像度を自由に変えられます。  
  Change the taxonomic resolution (e.g., Phylum, Class) using the menu at the top of the plot.
- **Sort / Color:** メタデータ（map.txt に記載されたサンプルの採取場所や条件など）に基づいて、グラフの並び替えや色分けが可能です。  
  Sort and color samples based on metadata (e.g., sampling location or condition) recorded in map.txt.

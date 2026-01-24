set terminal pngcairo size 800,600

set datafile separator "\t"
set datafile columnheaders

set grid
set key spacing 1.2
set rmargin 6

set style line 1 lw 2 pt 7 ps 0.5
set style line 2 lw 2 pt 7 ps 0.5
set style line 3 lw 2 pt 7 ps 0.5
set style line 4 lw 2 pt 7 ps 0.5

files  = "bpe unigram word char"
labels = "BPE ULM Word Char"

set output results_dir."/r2.png"

set key right bottom

set title "R^2 Score vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "R^2 Score"

plot for [i=1:4] \
  sprintf(results_dir."/%s.tsv", word(files,i)) \
  using "vocab_size":"R^2" with linespoints ls i title word(labels,i)

set output

set output results_dir."/mae.png"

set key right top

set title "MAE vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "MAE"

plot for [i=1:4] \
  sprintf(results_dir."/%s.tsv", word(files,i)) \
  using "vocab_size":"MAE" with linespoints ls i title word(labels,i)

set output

set output results_dir."/tokens_per_sent.png"

set key right top

set title "#tokens/sent vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "#tokens/sent"

plot for [i=1:3] \
  sprintf(results_dir."/%s.tsv", word(files,i)) \
  using "vocab_size":"#tokens/sent" with linespoints ls i title word(labels,i)

set output

set output results_dir."/chars_per_token.png"

set key right bottom

set title "#chars/token vs Vocab Size"
set xlabel "Vocabulary Size"
set ylabel "#chars/token"

plot for [i=1:3] \
  sprintf(results_dir."/%s.tsv", word(files,i)) \
  using "vocab_size":"#chars/token" with linespoints ls i title word(labels,i)

set output

algorithms = "unigram bpe word char"
vocab_sizes = "4000 8000 16000 24000 32000 48000 64000 96000 128000"

do for [a in algorithms] {

    outfile = sprintf(results_dir."/zipf_%s.png", a)

    set output outfile
 
    set key right top
 
    set title sprintf("Zipf Plot for Different Vocabulary Sizes (algorithm = %s)", a)
    set xlabel "log(rank)"
    set ylabel "log(freq)"

    set style line 1 pt 7 ps 0.3
    set style line 2 pt 7 ps 0.3
    set style line 3 pt 7 ps 0.3
    set style line 4 pt 7 ps 0.3

    plot \
      sprintf(results_dir."/%s_8000/tokens.tsv", a)  using "log_rank":"log_freq" with points ls 1 title "8k", \
      sprintf(results_dir."/%s_32000/tokens.tsv", a)  using "log_rank":"log_freq" with points ls 2 title "32k", \
      sprintf(results_dir."/%s_64000/tokens.tsv", a)  using "log_rank":"log_freq" with points ls 3 title "64k", \
      sprintf(results_dir."/%s_96000/tokens.tsv", a) using "log_rank":"log_freq" with points ls 4 title "96k"

    set output
}

# ---------------------------------------------------------
# gnuplot script for Zipf's Law Analysis (Split Files)
# ---------------------------------------------------------

# --- 出力形式の設定 ---
# 画像サイズを少し小さく調整（1枚ずつになるため）
set terminal pngcairo size 800,600 enhanced font 'Times New Roman,14'

# --- 共通スタイル設定 ---
set grid back lc rgb '#dddddd' lt 1   # 背景グリッド
set border 31 lc rgb 'black' lw 1.5   # 枠線
set tics out nomirror
set mxtics 5
set mytics 5

# スタイル定義
set style line 1 pt 7 ps 0.8 lc rgb '#660055AA'  # データ点（透過青）
set style line 2 lt 2 lw 2 lc rgb '#D62728'      # モデル（赤破線）
set style line 4 lt 1 lw 2 lc rgb '#D62728'      # ゼロライン（赤実線）

# ループ開始
do for [a in algorithms] {
    do for [s in vocab_sizes] {

        # 入力ファイル名を定義（読みやすくするため）
        input_file = sprintf(results_dir."/%s_%s/piantadosi.tsv", a, s)

        # -----------------------------------------------------
        # 1枚目: Rank-Frequency Distribution
        # -----------------------------------------------------
        # 出力ファイル名を設定 (例: ..._dist.png)
        set output sprintf(results_dir."/piantadosi_%s_%s_dist.png", a, s)

        set title "(a) Rank-Frequency Distribution" offset 0,-1
        set xlabel "Log_{10}(Rank)"
        set ylabel "Log_{10}(Normalized Frequency)"
        set key top right box opaque
        
        # 範囲を自動調整にリセット
        set autoscale x
        set autoscale y

        # プロット実行（行末のバックスラッシュ \ を削除しました）
        plot input_file using 1:2 notitle with points ls 1, \
             input_file using 1:3 title "Fitted Model" with lines ls 2

        set output

        # -----------------------------------------------------
        # 2枚目: Residuals of Fit
        # -----------------------------------------------------
        # 出力ファイル名を設定 (例: ..._resid.png)
        set output sprintf(results_dir."/piantadosi_%s_%s_resid.png", a, s)

        set title "(b) Residuals of Fit" offset 0,-1
        set xlabel "Log_{10}(Rank)"
        set ylabel "Error (log space)"
        
        # 残差プロット用の範囲設定
        # 論文のように高頻度語（ランク小）にフォーカスするなら範囲を指定
        # set xrange [*:0.95] 
        set autoscale x      # 全体を見たい場合は autoscale
        set yrange [-0.15:0.15]

        # プロット実行
        plot input_file using 1:($2-$3) title "Residuals" with points ls 1, \
             0 title "Zero Error" with lines ls 4

        # ファイルを閉じる
        set output
    }
}

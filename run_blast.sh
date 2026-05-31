#!/bin/bash

# if error occur stop analysis
set -e

# Checking the argument (durecly name)
TARGET_DIR=$1
if [ -z "$TARGET_DIR" ]; then
  echo "Error"
  echo "EX: bash scripts/run_qiime2_vsearch.sh analysis/HIroshimabay_2025_18S"
  exit 1
fi

# Obtaining a full pass
WORK_DIR="/home/kenji/work/Taxonomic_analysis/${TARGET_DIR}"

if [ ! -d "$WORK_DIR" ]; then
  echo "Error: Folder not found -> $WORK_DIR"
  exit 1
fi

echo "QIIME 2 start for taxonomic analysis: $TARGET_DIR"

cd "$WORK_DIR"

# 1. Performing Phylogenetic Classification (Consensus VSEARCH)
echo "1. Taxo analysis (VSEARCH)"
qiime feature-classifier classify-consensus-vsearch \
  --i-query repset.qza \
  --i-reference-reads ../../database/silva-138-99-seqs.qza \
  --i-reference-taxonomy ../../database/silva-138-99-tax.qza \
  --p-perc-identity 0.97 \
  --p-query-cov 0.80 \
  --p-maxaccepts 10 \
  --p-min-consensus 0.51 \
  --p-threads 40 \
  --o-classification my_taxonomy_vsearch.qza \
  --o-search-results search_results.qza

# 2. Data export (TSV x 2)
echo "2. Data export"
qiime tools export --input-path my_taxonomy_vsearch.qza --output-path exported-taxonomy
qiime tools export --input-path table.qza --output-path exported-table
biom convert -i exported-table/feature-table.biom -o asv_counts.tsv --to-tsv

# 3. Visualisation (Creating QZV files)
echo "3. Making visualizations"
qiime metadata tabulate \
  --m-input-file my_taxonomy_vsearch.qza \
  --o-visualization taxonomy.qzv
qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy my_taxonomy_vsearch.qza \
  --m-metadata-file map.txt \
  --o-visualization taxa-bar-plots.qzv

echo "END"
INPUT="$1"
OUTPUT="$2"
STR="${OUTPUT:3}"
DATA=$OUTPUT
DATA_DIR=${DATA%/*}
DATA_BASE="${DATA/$DATA_DIR/}"
DATA_BASE="${DATA_BASE/.md/}"

# From https://stackoverflow.com/a/246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir -p $DATA_DIR

node "$DIR\..\tools\md_json\bin\md-json.js" \
-md markdown-it-abbr markdown-it-attrs markdown-it-emoji markdown-it-footnote markdown-it-headinganchor \
-i $INPUT -o $OUTPUT
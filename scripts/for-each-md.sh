INPUT="$@"

STR="${INPUT:3}"
DATA=$INPUT
DATA_DIR=${DATA%/*}
DATA_BASE="${DATA/$DATA_DIR/}"
DATA_BASE="${DATA_BASE/.md/}"

# From https://stackoverflow.com/a/246128
DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for file in $INPUT*.md; do
    SRC="${file:0:3}"
    NAME="${file/.md}"
    NAME="${NAME/*"/"}"
    DIR="${file:3}";
    DIR="${DIR/$NAME.md}"
    
    #echo "src = $SRC"
    #echo "dir = $DIR"
    #echo "name = $NAME"
    #echo "$SRC/data$DIR$NAME.json"

    $DIRECTORY/md-json.sh "$file" "$SRC/data$DIR$NAME.json"
done
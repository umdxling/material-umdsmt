export PYTHONIOENCODING=UTF-8

### Decoding only script
source=$1
target=$2
threads=$3
input_dir=/app/input
output_dir=/app/output

moses_path=/ubuntu-16.04/bin
moses_scripts_path=/ubuntu-16.04/scripts

roma_path=/uroman/bin

mkdir -p /tmp
tmp_output_dir=/tmp
output_sub_dir=$output_dir
url_table=$tmp_output_dir/url_table.json

## Call raw system
model_sub_dir=/app/models/raw
ln -sf $model_sub_dir/${source}2${target} /app/models/${source}2${target}

echo "Starting translation.."
echo "Preprocessing .."
date

ls $input_dir | while read var; do
	cat $input_dir/$var >> $tmp_output_dir/input
done;

# Tokenization
if [[ $source == fa ]] | [[ $target == fa ]]; then
	normalization_script=normalization2.1
else
	normalization_script=normalization
fi;

CHARS=$(echo -ne '\u200c')

if [[ $source == ka ]]; then
	cat ${tmp_output_dir}/input \
        	| sed 's/['"$CHARS"']//g'  \
        	| python3 -c "import sys;[sys.stdout.write(line.strip()+'\n') for line in sys.stdin]" \
                | python3 /app/scripts/replace-urls-in-text.py $url_table       \
		| python3 /app/scripts/$normalization_script.py $source \
        	| $moses_scripts_path/tokenizer/normalize-punctuation.perl -l en  \
        	| $moses_scripts_path/tokenizer/tokenizer.perl -q -l en -a -no-escape -threads ${threads} \
        	| $moses_scripts_path/tokenizer/escape-special-chars.perl \
        	> $tmp_output_dir/input.tok 2> /dev/null
else
	cat ${tmp_output_dir}/input \
        	| sed 's/['"$CHARS"']//g'  \
        	| python3 -c "import sys;[sys.stdout.write(line.strip()+'\n') for line in sys.stdin]" \
        	| python3 /app/scripts/$normalization_script.py $source \
        	| $moses_scripts_path/tokenizer/normalize-punctuation.perl -l en  \
        	| $moses_scripts_path/tokenizer/tokenizer.perl -q -l en -a -no-escape -threads ${threads} \
        	| $moses_scripts_path/tokenizer/escape-special-chars.perl \
        	> $tmp_output_dir/input.tok 2> /dev/null
fi;

wc -l $tmp_output_dir/input.tok
# True-casing
if [[ $source == ps ]]; then
    $moses_scripts_path/recaser/truecase.perl                     \
            -model $model_sub_dir/${source}2${target}/tc.${source}    \
            < $tmp_output_dir/input.tok                             \
            | $roma_path/uroman.pl -l pus                           \
            > $tmp_output_dir/input.tok.tc

else
    $moses_scripts_path/recaser/truecase.perl                     \
            -model $model_sub_dir/${source}2${target}/tc.${source}    \
            < $tmp_output_dir/input.tok                             \
            > $tmp_output_dir/input.tok.tc
fi;

wc -l $tmp_output_dir/input.tok.tc
# BPE
if [[ $source != so ]] && [[ $target != so ]]; then
        cat $tmp_output_dir/input.tok.tc > $tmp_output_dir/input.tok.tc.bpe
else
        python3 /app/scripts/apply_bpe.py                    \
                --codes $model_sub_dir/${source}2${target}/bpe   \
                < $tmp_output_dir/input.tok.tc                 \
                > $tmp_output_dir/input.tok.tc.bpe
fi;

wc -l $tmp_output_dir/input.tok.tc.bpe

echo -n "Done @ "
date
## decode
echo " ** Decoding..."
rm -rf $tmp_output_dir/filtered_table
## retain the entries needed translate the test set.
$moses_scripts_path/training/filter-model-given-input.pl \
        $tmp_output_dir/filtered_table     \
        $model_sub_dir/${source}2${target}/moses.ini         \
        $tmp_output_dir/input.tok.tc.bpe \
        -Binarizer $moses_path/processPhraseTableMin \

$moses_path/moses \
        -config $tmp_output_dir/filtered_table/moses.ini   \
        -alignment-output-file $tmp_output_dir/output.align  \
        -threads ${threads} \
        < $tmp_output_dir/input.tok.tc.bpe \
        > $tmp_output_dir/output.trans.tc.tok \
        2> $tmp_output_dir/output_log

if [[ $source == ka ]]; then
	cat $tmp_output_dir/output.trans.tc.tok \
		| perl -pe 's/@@ //g' 2>/dev/null \
		| $moses_scripts_path/tokenizer/deescape-special-chars.perl 2> /dev/null \
		| $moses_scripts_path/recaser/detruecase.perl 2>/dev/null \
		| $moses_scripts_path/tokenizer/detokenizer.perl -q -l en 2>/dev/null \
		| python3 /app/scripts/recover-urls.py $url_table \
		> $tmp_output_dir/output.trans
else
	cat $tmp_output_dir/output.trans.tc.tok \
		| perl -pe 's/@@ //g' 2>/dev/null \
		| $moses_scripts_path/tokenizer/deescape-special-chars.perl 2> /dev/null \
		| $moses_scripts_path/recaser/detruecase.perl 2>/dev/null \
		| $moses_scripts_path/tokenizer/detokenizer.perl -q -l en 2>/dev/null \
		> $tmp_output_dir/output.trans
fi;
echo -n "Done @ "
date

echo "Postprocessing ... "
python /app/scripts/split.py $tmp_output_dir/output.trans ${input_dir} ${output_sub_dir}
python /app/scripts/split.py $tmp_output_dir/output.trans.tc.tok ${input_dir} ${output_sub_dir} .trans
python /app/scripts/split.py $tmp_output_dir/output.align ${input_dir} ${output_sub_dir} .align
python /app/scripts/split.py $tmp_output_dir/input.tok.tc.bpe ${input_dir} ${output_sub_dir} .input
echo -n "Done @ "
date

rm -rf /app/models/${source}2${target}
rm -rf $tmp_output_dir/*
chmod -R 777 $output_dir

if [[ $target != en ]]; then
	exit;
fi;

## Call stemming system
model_sub_dir=/app/models/stem
ln -sf $model_sub_dir/${source}2${target} /app/models/${source}2${target}

echo "Starting translation.. stem"
echo "Preprocessing .."
date

ls $input_dir | while read var; do
	cat $input_dir/$var >> $tmp_output_dir/input
done

# Stemming
python /app/scripts/parse_from_json.py ${tmp_output_dir}/input $tmp_output_dir/input.stem


if [[ $source == fa ]] | [[ $target == fa ]]; then
        normalization_script=normalization2.1
else
        normalization_script=normalization
fi;

CHARS=$(echo -ne '\u200c')

# Tokenization
if [[ $source == en ]]; then
        cat $tmp_output_dir/input.stem \
		| python3 /app/scripts/$normalization_script.py $source \
                | $moses_scripts_path/tokenizer/normalize-punctuation.perl -l en  \
                | $moses_scripts_path/tokenizer/escape-special-chars.perl \
                > $tmp_output_dir/input.tok 2> /dev/null
elif [[ $source == ka ]]; then
        cat $tmp_output_dir/input.stem \
                | sed 's/['"$CHARS"']//g'  \
                | python3 -c "import sys;[sys.stdout.write(line.strip()+'\n') for line in sys.stdin]" \
		| python3 /app/scripts/replace-urls-in-text.py $url_table \
                | python3 /app/scripts/$normalization_script.py $source \
                | $moses_scripts_path/tokenizer/normalize-punctuation.perl -l en  \
                | $moses_scripts_path/tokenizer/tokenizer.perl -q -l en -a -no-escape -threads ${threads} \
                | $moses_scripts_path/tokenizer/escape-special-chars.perl \
                > $tmp_output_dir/input.tok 2> /dev/null

else
	cat $tmp_output_dir/input.stem \
        	| sed 's/['"$CHARS"']//g'  \
        	| python3 -c "import sys;[sys.stdout.write(line.strip()+'\n') for line in sys.stdin]" \
		| python3 /app/scripts/$normalization_script.py $source \
                | $moses_scripts_path/tokenizer/normalize-punctuation.perl -l en  \
                | $moses_scripts_path/tokenizer/tokenizer.perl -q -l en -a -no-escape -threads ${threads} \
                | $moses_scripts_path/tokenizer/escape-special-chars.perl \
                > $tmp_output_dir/input.tok 2> /dev/null
fi;


# True-casing
if [[ $source == ps ]]; then
    $moses_scripts_path/recaser/truecase.perl \
            -model $model_sub_dir/${source}2${target}/tc.${source}    \
            < $tmp_output_dir/input.tok                   \
            | $roma_path/uroman.pl -l pus                   \
            > $tmp_output_dir/input.tok.tc
else
    $moses_scripts_path/recaser/truecase.perl \
            -model $model_sub_dir/${source}2${target}/tc.${source}    \
            < $tmp_output_dir/input.tok                   \
            > $tmp_output_dir/input.tok.tc
fi;
        

echo -n "Done @ "
date
## decode
echo " ** Decoding..."
rm -rf $tmp_output_dir/filtered_table
## retain the entries needed translate the test set.
$moses_scripts_path/training/filter-model-given-input.pl \
        $tmp_output_dir/filtered_table     \
        $model_sub_dir/${source}2${target}/moses.ini         \
        $tmp_output_dir/input.tok.tc \
        -Binarizer $moses_path/processPhraseTableMin \

$moses_path/moses \
        -config $tmp_output_dir/filtered_table/moses.ini   \
        -alignment-output-file $tmp_output_dir/output.align  \
        -threads ${threads} \
        < $tmp_output_dir/input.tok.tc \
        > $tmp_output_dir/output.trans.tc.tok \
        2> $tmp_output_dir/output_log

if [[ $source == ka ]]; then
	cat $tmp_output_dir/output.trans.tc.tok \
		| perl -pe 's/@@ //g' 2>/dev/null \
		| $moses_scripts_path/tokenizer/deescape-special-chars.perl 2> /dev/null \
		| $moses_scripts_path/recaser/detruecase.perl 2>/dev/null \
		| $moses_scripts_path/tokenizer/detokenizer.perl -q -l en 2>/dev/null \
		| python3 /app/scripts/recover-urls.py $url_table	\
		> $tmp_output_dir/output.trans
else
	cat $tmp_output_dir/output.trans.tc.tok \
		| perl -pe 's/@@ //g' 2>/dev/null \
		| $moses_scripts_path/tokenizer/deescape-special-chars.perl 2> /dev/null \
		| $moses_scripts_path/recaser/detruecase.perl 2>/dev/null \
		| $moses_scripts_path/tokenizer/detokenizer.perl -q -l en 2>/dev/null \
		> $tmp_output_dir/output.trans
fi;
echo -n "Done @ "
date

echo "Postprocessing ... "
python /app/scripts/split.py $tmp_output_dir/output.trans ${input_dir} ${output_sub_dir} .stem
python /app/scripts/split.py $tmp_output_dir/output.trans.tc.tok ${input_dir} ${output_sub_dir} .stem.trans
python /app/scripts/split.py $tmp_output_dir/output.align ${input_dir} ${output_sub_dir} .stem.align
python /app/scripts/split.py $tmp_output_dir/input.tok.tc ${input_dir} ${output_sub_dir} .stem.input
echo -n "Done @ "
date

rm -rf /app/models/${source}2${target}
rm -rf $tmp_output_dir/*
chmod -R 777 $output_dir

date
#####
exit;
#####



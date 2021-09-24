# material-umdsmt

## Introduction

This is a pipeline for building and releasing statistical machine translation systems. It can be used to translate a directory of small documents.

The system runs in one [Docker](https://www.docker.com/) container.


## Supported language directions and features

Supported language directions include English to/from Swahili (sw), Tagalog (tl), Somali (so), Pashto (ps), Lithuanian (lt), Bulgarian (bg), Farsi (fa), Kazakh (kk), and Georgian (ka). Not all language directions support all features. The following table lists the features supported for each language direction (as of models v7.2).

- Text is normal text translation.
- Stem are models that translate from non-English into lemmatized English sentences.

|       |text |stem   |
|-------|-----|-------|
|en<>sw |ok   |sw->en |
|en<>tl |ok   |tl->en |
|en<>so |ok   |so->en |
|en<>ps |ok   |ps->en |
|en<>lt |ok   |lt->en |
|en<>bg |ok   |bg->en |
|en<>fa |ok   |fa->en |
|en<>kk |ok   |kk->en |
|en<>ka |ok   |ka->en |


## Requirements

- [Docker](https://www.docker.com/)


## Run the Docker translator to translate a single folder

The Docker image comes with a translation function that translates input folders on the command line (note that the directories need to be located where docker has read/write permissions). For this, you need to mount volumes in the docker container as shown in the examples below:

```
docker run --rm \
  -v <input_dir>:/mt/input_dir \
  -v <output_dir>:/mt/output_dir \
  --name umdsmt \
  umd-smt:v3.7.3 \
  <src_lang> <tgt_lang> <num_threads>
```

### Input/Output Format

The input to the command is a directory (possibly with subdirectories) containing all files to be translated. The output is a new directory with the same subdirectories and the same file names, but containing standard/stemmed translations. Given an input file `file.txt`, it produces
- `file.txt`: plain translation file aligned with the input.
- `file.txt.input`: the preprocessed input.
- `file.txt.trans`: the translation file before post-processing.
- `file.txt.align`: word alignments between sentences in file.txt.input and file.txt.trans.
- `file.txt.stem`: plain stemmed translation file aligned with the input (only if tgt_lang=en).
- `file.txt.stem.input`: the preprocessed input for stemmed translation.
- `file.txt.stem.trans`: the stemmed translation before post-processing.
- `file.txt.stem.align`: word alignments between sentences in file.txt.stem.input and file.txt.stem.trans.


## Building the Docker image

The Makefile includes commands for `docker-build` for convenience. You can always invoke `docker build` manually with your own settings instead. 

To build, you will need the model directories for text (raw) and stem, each of which contains subdirectories for each of the translation directions. The subdirectory should contain all of the necessary bpe model, truecase model, the MT models themselves, etc., for example:

```
raw
├── ka2en
│   ├── aligned.grow-diag-final-and
│   ├── bpe
│   ├── lex.e2f
│   ├── lex.f2e
│   ├── lm.en.bitext.train.norm.tok.langid.tc.url.clean.bin
│   ├── lm_mono.en.bitext.train.norm.tok.langid.tc.url.clean.bin
│   ├── moses.ini
│   ├── phrase-table.gz
│   ├── reordering-table.wbe-msd-bidirectional-fe.gz
│   ├── tc.ka
stem
├── ka2en
│   ├── aligned.grow-diag-final-and
│   ├── bpe
│   ├── lex.e2f
│   ├── lex.f2e
│   ├── lm.en.bitext.train.norm.tok.langid.tc.url.clean.bin
│   ├── lm_mono.en.bitext.train.norm.tok.langid.tc.url.clean.bin
│   ├── moses.ini
│   ├── phrase-table.gz
│   ├── reordering-table.wbe-msd-bidirectional-fe.gz
│   ├── tc.ka
...
``` 

To build, run:

```
make docker-build
```

This is equivalent to:

```
docker build ​​-t umd-smt:${DOCKER_VERSION} -f Dockerfile .
```

where `${DOCKER_VERSION}` is found in `configs/env_build.sh` by the `Makefile`.


## For Developers

### Creating a new release

#### Adding text pre-/post-processing plugins

If your model uses a new data pre-/post-processing pipeline, you will need to add it to the preprocessing pipeline in `scripts/decode_load_first.sh` (line 32-89).

#### Release

Next, follow these steps to create a new docker image and publish a new version of this repo:

1. Update `configs/env_build.sh` with a new model version and other docker build settings.
2. Build the docker:
```
make docker-build
```
3. Save the docker into a tar file:
```
make docker-save
```

### Code walkthrough

The following is a brief walkthrough of some of the included files, to aid in development and debugging:

- *Dockerfile*: creates the docker image

- *Makefile*: used for building both the docker, and the internal systems
   - Includes `docker-build` command, which read from configs so developer-users only need to make small changes to rebuild with new settings.
   - Contains commands to build tools and systems, which can be used by developer-users to build everything locally (outside of Docker) and which are also used by the Dockerfile to build tools and systems.

- *configs/*: central location for any type of configuration files

- *configs/env_build.sh*: config for `docker build`, including URLs of where to download systems and tools, the MODEL_VERSION, and other docker build settings

- *scripts/*: central location for any scripts having to do with translation
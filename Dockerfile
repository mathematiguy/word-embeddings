FROM dragonflyscience/dragonverse-18.04

USER root

RUN apt update

RUN Rscript -e 'install.packages("igraph")'
RUN Rscript -e 'install.packages("bookdown")'
RUN Rscript -e 'devtools::install_github("pommedeterresautee/fastrtext")'
RUN Rscript -e 'install.packages("ggnetwork")'

# Install python + other things
RUN apt install -y python3-dev python3-pip

COPY submodules/fastText /code/submodules/fastText
WORKDIR /code/submodules/fastText
RUN make && cp fasttext /usr/bin

COPY requirements.txt /root/requirements.txt
COPY submodules/reo-toolkit /code/submodules/reo-toolkit

RUN pip3 install -r /root/requirements.txt

ENV NLTK_DATA /nltk_data
RUN python3 -c "import nltk;nltk.download('punkt', download_dir='$NLTK_DATA')"

RUN apt update
RUN apt install -y nodejs-dev node-gyp libssl1.0-dev npm

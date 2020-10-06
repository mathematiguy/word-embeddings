FROM dragonflyscience/dragonverse-18.04

USER root

RUN apt update

# Install python + other things
RUN apt install -y python3-dev python3-pip

COPY requirements.txt /root/requirements.txt
COPY reo-toolkit /code/reo-toolkit

RUN pip3 install -r /root/requirements.txt

ENV NLTK_DATA /nltk_data
RUN python3 -c "import nltk;nltk.download('punkt', download_dir='$NLTK_DATA')"

RUN apt install -y libglpk-dev python-igraph

RUN Rscript -e 'install.packages("igraph")'
RUN Rscript -e 'install.packages("bookdown")'
RUN Rscript -e 'devtools::install_github("pommedeterresautee/fastrtext")'
RUN Rscript -e 'install.packages("ggnetwork")'

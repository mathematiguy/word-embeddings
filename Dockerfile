FROM dragonflyscience/dragonverse-18.04

USER root

RUN apt update

# Install R packages
RUN Rscript -e 'install.packages("igraph")'
RUN Rscript -e 'install.packages("bookdown")'
RUN Rscript -e 'devtools::install_github("pommedeterresautee/fastrtext")'
RUN Rscript -e 'install.packages("ggnetwork")'

# Install python + other things
RUN apt update
RUN apt install -y python3-dev python3-pip node-gyp libssl1.0-dev npm tree nodejs-dev

# Install fasttext
COPY submodules/fastText /code/submodules/fastText
WORKDIR /code/submodules/fastText
RUN make && cp fasttext /usr/bin

# Install nodejs
RUN apt-get update
RUN apt-get -y install curl gnupg
RUN curl -sL https://deb.nodesource.com/setup_15.x  | bash -
RUN apt-get -y install nodejs
RUN npm install

# RUN apt update && apt install -y llvm-10-dev
RUN python3 -m pip install --upgrade pip
COPY requirements.txt /root/requirements.txt
COPY submodules/reo-toolkit /code/submodules/reo-toolkit
RUN pip3 install -r /root/requirements.txt

# Add plotly extensions to jupyterlab
RUN jupyter labextension install jupyterlab-plotly@4.11.0
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager plotlywidget@4.11.0

# Install nltk tokenizers package (punkt)
ENV NLTK_DATA /nltk_data
RUN python3 -c "import nltk;nltk.download('punkt', download_dir='$NLTK_DATA')"

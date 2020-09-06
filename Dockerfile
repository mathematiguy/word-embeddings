FROM ubuntu:18.04

USER root

RUN apt update

# Install python + other things
RUN apt install -y python3-dev python3-pip

COPY requirements.txt /root/requirements.txt
COPY reo-toolkit /code/reo-toolkit

RUN pip3 install -r /root/requirements.txt

ENV NLTK_DATA /nltk_data
RUN python3 -c "import nltk;nltk.download('punkt', download_dir='$NLTK_DATA')"


FROM python:3.11

WORKDIR /app

COPY . ./app
RUN pip3 install -r ./app/requirements.txt
EXPOSE 8000
CMD ["mkdocs", "serve", "-f", "./app/mkdocs.yml", "--dev-addr=0.0.0.0:8000"]

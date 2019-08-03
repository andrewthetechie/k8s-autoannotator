from python:3.7-slim

COPY auto-annotator.py /
COPY requirements.txt /
RUN pip install --no-cache -r requirements.txt && \
  rm requirements.txt

CMD python /auto-annotator.py
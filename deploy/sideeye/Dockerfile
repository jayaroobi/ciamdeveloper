FROM python:3.12-slim

WORKDIR /app

COPY sideeye/requirements.txt /app/sideeye/requirements.txt
RUN pip install --no-cache-dir -r /app/sideeye/requirements.txt

COPY sideeye /app/sideeye
ENV PYTHONPATH=/app
ENV SIDEYE_STATE_DIR=/mnt/sideeye-state

# Matches architecture label: Pod ciam-reviewer --profile NAME
ENTRYPOINT ["python", "-m", "sideeye"]

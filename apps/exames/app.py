import logging
import os
from pythonjsonlogger.json import JsonFormatter
from flask import Flask, jsonify, request

app = Flask(__name__)
logger = logging.getLogger("legacy-exames")
logger.setLevel(logging.INFO)
handler = logging.FileHandler(os.getenv("APP_LOG_FILE", "/logs/app.json"))
handler.setFormatter(JsonFormatter("%(asctime)s %(levelname)s %(name)s %(message)s"))
logger.addHandler(handler)

@app.get("/")
def index():
    logger.info("consulta_exame", extra={"application": "exames", "path": request.path})
    return jsonify(service="exames", status="ok", message="Protegida pelo Authentik Proxy")

@app.get("/health")
def health():
    return jsonify(status="ok")

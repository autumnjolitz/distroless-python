import platform

from flask import Flask

app = Flask(__name__)


@app.route("/")
def hello_world() -> str:
    return "<p>Hello, World!</p>"


@app.route("/_health")
def check_health() -> str:
    return "ok"


@app.route("/_arch")
def show_config() -> str:
    return platform.uname().machine

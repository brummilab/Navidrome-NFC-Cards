import os
import sys
import logging
from flask import Flask, render_template, request, jsonify, redirect, url_for, flash

# Allow running as `python -m src.web.app` from project root
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from src.config import load_config
from src.navidrome import NavidromeClient
from src.mappings import MappingDB
from src.nfc_reader import get_card_uid

logger = logging.getLogger(__name__)


def create_app(config_path: str = "config.yaml") -> Flask:
    app = Flask(__name__)

    cfg = load_config(config_path)
    app.secret_key = cfg["web"]["secret_key"]

    navidrome = NavidromeClient(
        cfg["navidrome"]["url"],
        cfg["navidrome"]["username"],
        cfg["navidrome"]["password"],
    )
    db = MappingDB(cfg["data"]["db_path"])
    reader_index = cfg.get("nfc", {}).get("reader_index", 0)

    @app.route("/")
    def index():
        mappings = db.list_mappings()
        return render_template("index.html", mappings=mappings)

    @app.route("/search")
    def search():
        query = request.args.get("q", "").strip()
        uid = request.args.get("uid", "").strip()
        results = {}
        if query:
            try:
                results = navidrome.search(query, album_count=15, song_count=10, artist_count=5)
            except Exception as e:
                flash(f"Navidrome-Fehler: {e}", "danger")
        return render_template("search.html", query=query, uid=uid, results=results, navidrome=navidrome)

    @app.route("/scan")
    def scan():
        return render_template("scan.html")

    @app.route("/api/card")
    def api_card():
        uid = get_card_uid(reader_index)
        return jsonify({"uid": uid})

    @app.route("/api/map", methods=["POST"])
    def api_map():
        data = request.json or {}
        required = ["uid", "item_type", "item_id", "name"]
        if not all(k in data for k in required):
            return jsonify({"error": "Fehlende Felder"}), 400
        db.add_mapping(
            uid=data["uid"],
            item_type=data["item_type"],
            item_id=data["item_id"],
            name=data["name"],
            artist=data.get("artist"),
            cover_url=data.get("cover_url"),
        )
        return jsonify({"ok": True})

    @app.route("/api/map/<path:uid>", methods=["DELETE"])
    def api_delete_map(uid):
        deleted = db.delete_mapping(uid)
        return jsonify({"ok": deleted})

    return app


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    config_path = os.environ.get("CONFIG_PATH", "config.yaml")
    flask_app = create_app(config_path)
    flask_app.run(host="0.0.0.0", port=8080, debug=False)

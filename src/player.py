import subprocess
import threading
import logging
from typing import Optional

from .navidrome import NavidromeClient

logger = logging.getLogger(__name__)


class Player:
    def __init__(self, navidrome: NavidromeClient, mode: str = "mpv", mpv_options: list = None):
        self.navidrome = navidrome
        self.mode = mode
        self.mpv_options = mpv_options or []
        self._process: Optional[subprocess.Popen] = None
        self._lock = threading.Lock()

    def play(self, item_type: str, item_id: str) -> bool:
        try:
            songs = self._get_songs(item_type, item_id)
            if not songs:
                logger.warning(f"No songs found for {item_type}:{item_id}")
                return False
            if self.mode == "jukebox":
                return self._play_jukebox(songs)
            return self._play_mpv(songs)
        except Exception as e:
            logger.error(f"Playback error: {e}")
            return False

    def stop(self):
        if self.mode == "jukebox":
            self.navidrome.jukebox_stop()
        else:
            self._stop_mpv()

    def _get_songs(self, item_type: str, item_id: str) -> list:
        if item_type == "album":
            return self.navidrome.get_album_songs(item_id)
        if item_type == "track":
            song = self.navidrome.get_song(item_id)
            return [song] if song else []
        if item_type == "playlist":
            return self.navidrome.get_playlist_songs(item_id)
        if item_type == "artist":
            artist = self.navidrome.get_artist(item_id)
            songs = []
            for album in artist.get("album", []):
                songs.extend(self.navidrome.get_album_songs(album["id"]))
            return songs
        return []

    def _play_jukebox(self, songs: list) -> bool:
        return self.navidrome.jukebox_play([s["id"] for s in songs])

    def _play_mpv(self, songs: list) -> bool:
        with self._lock:
            self._stop_mpv()
            urls = [self.navidrome.get_stream_url(s["id"]) for s in songs]
            cmd = ["mpv", "--no-video"] + self.mpv_options + urls
            self._process = subprocess.Popen(
                cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
        logger.info(f"Started mpv with {len(urls)} tracks")
        return True

    def _stop_mpv(self):
        if self._process and self._process.poll() is None:
            self._process.terminate()
            try:
                self._process.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self._process.kill()
        self._process = None

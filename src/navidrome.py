import hashlib
import secrets
import requests


class NavidromeClient:
    def __init__(self, url: str, username: str, password: str, client: str = "navidrome-nfc"):
        self.url = url.rstrip("/")
        self.username = username
        self.password = password
        self.client = client

    def _auth_params(self) -> dict:
        salt = secrets.token_hex(8)
        token = hashlib.md5(f"{self.password}{salt}".encode()).hexdigest()
        return {
            "u": self.username,
            "t": token,
            "s": salt,
            "v": "1.16.1",
            "c": self.client,
            "f": "json",
        }

    def _get(self, endpoint: str, **params) -> dict:
        response = requests.get(
            f"{self.url}/rest/{endpoint}",
            params={**self._auth_params(), **params},
            timeout=10,
        )
        response.raise_for_status()
        data = response.json()
        result = data.get("subsonic-response", {})
        if result.get("status") != "ok":
            error = result.get("error", {}).get("message", "unknown")
            raise RuntimeError(f"Subsonic API error: {error}")
        return result

    def ping(self) -> bool:
        try:
            self._get("ping")
            return True
        except Exception:
            return False

    def search(self, query: str, album_count: int = 15, song_count: int = 10, artist_count: int = 5) -> dict:
        result = self._get(
            "search3",
            query=query,
            albumCount=album_count,
            songCount=song_count,
            artistCount=artist_count,
        )
        return result.get("searchResult3", {})

    def get_album(self, album_id: str) -> dict:
        result = self._get("getAlbum", id=album_id)
        return result.get("album", {})

    def get_artist(self, artist_id: str) -> dict:
        result = self._get("getArtist", id=artist_id)
        return result.get("artist", {})

    def get_song(self, song_id: str) -> dict:
        result = self._get("getSong", id=song_id)
        return result.get("song", {})

    def get_album_songs(self, album_id: str) -> list:
        return self.get_album(album_id).get("song", [])

    def get_playlists(self) -> list:
        result = self._get("getPlaylists")
        return result.get("playlists", {}).get("playlist", [])

    def get_playlist_songs(self, playlist_id: str) -> list:
        result = self._get("getPlaylist", id=playlist_id)
        return result.get("playlist", {}).get("entry", [])

    def get_stream_url(self, song_id: str) -> str:
        params = {**self._auth_params(), "id": song_id}
        param_str = "&".join(f"{k}={v}" for k, v in params.items())
        return f"{self.url}/rest/stream?{param_str}"

    def get_cover_url(self, item_id: str, size: int = 200) -> str:
        params = {**self._auth_params(), "id": item_id, "size": size}
        param_str = "&".join(f"{k}={v}" for k, v in params.items())
        return f"{self.url}/rest/getCoverArt?{param_str}"

    def jukebox_play(self, song_ids: list) -> bool:
        try:
            # setPlaylist expects multiple id params
            auth = self._auth_params()
            params = {**auth, "action": "setPlaylist"}
            for i, sid in enumerate(song_ids):
                params[f"id[{i}]"] = sid
            response = requests.get(f"{self.url}/rest/jukeboxControl", params=params, timeout=10)
            response.raise_for_status()
            self._get("jukeboxControl", action="start")
            return True
        except Exception:
            return False

    def jukebox_stop(self) -> bool:
        try:
            self._get("jukeboxControl", action="stop")
            return True
        except Exception:
            return False

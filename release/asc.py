"""App Store Connect API client — the thin slice the release pipeline needs.

Auth is an ES256 JWT signed with the account's .p8 key. The token is minted per
process and lives 20 minutes, which is the ceiling Apple enforces; a pipeline run
that outlives it re-mints on demand rather than failing halfway through a locale
loop.

Nothing here submits anything for review. That is deliberate and permanent: the
Submit button belongs to the owner, so this module carries no call that could
press it even by accident.
"""

from __future__ import annotations

import time
from pathlib import Path
from typing import Any

import jwt
import requests

BASE = "https://api.appstoreconnect.apple.com/v1"

KEY_ID = "L2R2R3YDY9"
ISSUER_ID = "69a6de93-2ec3-47e3-e053-5b8c7c11a4d1"
KEY_PATH = Path.home() / ".appstoreconnect/private_keys" / f"AuthKey_{KEY_ID}.p8"
APP_ID = "6738324344"
TEAM_ID = "379294YDPQ"
BUNDLE_ID = "simple-L.if-app.com"

# The store pack is written with the locale names a human uses; App Store Connect
# stores three of them under a region-qualified code. Getting this mapping wrong
# does not fail loudly — it silently writes nothing for de, fr and ar — so the
# pipeline resolves through this table and then verifies every locale it touched.
PACK_TO_ASC = {
    "en-GB": "en-GB",
    "uk": "uk",
    "de": "de-DE",
    "es-ES": "es-ES",
    "fr": "fr-FR",
    "pl": "pl",
    "zh-Hans": "zh-Hans",
    "ja": "ja",
    "ko": "ko",
    "ar": "ar-SA",
}


class ASCError(RuntimeError):
    """An App Store Connect response that carried an error payload."""


class ASC:
    def __init__(self, key_path: Path = KEY_PATH, key_id: str = KEY_ID,
                 issuer_id: str = ISSUER_ID, dry_run: bool = False):
        self.key = Path(key_path).read_text()
        self.key_id = key_id
        self.issuer_id = issuer_id
        self.dry_run = dry_run
        self._token = None
        self._token_exp = 0.0

    # ---- auth -------------------------------------------------------------

    def _auth_header(self) -> dict:
        now = time.time()
        if self._token is None or now > self._token_exp - 60:
            exp = int(now) + 1200
            self._token = jwt.encode(
                {"iss": self.issuer_id, "iat": int(now), "exp": exp,
                 "aud": "appstoreconnect-v1"},
                self.key, algorithm="ES256",
                headers={"kid": self.key_id, "typ": "JWT"},
            )
            self._token_exp = exp
        return {"Authorization": f"Bearer {self._token}"}

    # ---- transport --------------------------------------------------------

    def _request(self, method: str, path: str, *, params=None, json=None) -> Any:
        write = method.upper() in ("POST", "PATCH", "DELETE")
        if write and self.dry_run:
            print(f"  [dry-run] {method} {path}")
            if json:
                attrs = json.get("data", {}).get("attributes", {})
                for k, v in attrs.items():
                    shown = v if len(str(v)) < 60 else str(v)[:57] + "..."
                    print(f"             {k} = {shown!r}")
            return {"data": {"id": "dry-run-id", "attributes": {}}}

        url = path if path.startswith("http") else f"{BASE}{path}"
        r = requests.request(method, url, headers=self._auth_header(),
                             params=params, json=json, timeout=60)
        if r.status_code >= 400:
            raise ASCError(f"{method} {path} -> {r.status_code}\n{r.text[:900]}")
        return r.json() if r.text else {}

    def get(self, path, **params):
        return self._request("GET", path, params=params or None)

    def get_all(self, path, **params):
        """Follow paging. ASC caps `limit` at 200 and the release pipeline never
        needs that much, but a silently truncated locale list is exactly the kind
        of failure that looks like success."""
        params = dict(params)
        params.setdefault("limit", 200)
        out, url = [], None
        while True:
            page = self._request("GET", url or path, params=None if url else params)
            out.extend(page.get("data", []))
            url = page.get("links", {}).get("next")
            if not url:
                return out

    # ---- app store versions ----------------------------------------------

    def versions(self, **params):
        return self.get_all(f"/apps/{APP_ID}/appStoreVersions", **params)

    def find_version(self, version_string: str):
        for v in self.versions(**{"filter[platform]": "IOS",
                                  "fields[appStoreVersions]":
                                  "versionString,appStoreState,platform,createdDate"}):
            if v["attributes"]["versionString"] == version_string:
                return v
        return None

    def create_version(self, version_string: str, platform: str = "IOS"):
        body = {"data": {
            "type": "appStoreVersions",
            "attributes": {"platform": platform, "versionString": version_string},
            "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}},
        }}
        return self._request("POST", "/appStoreVersions", json=body)["data"]

    def delete_version(self, version_id: str):
        """Only ever valid while the version is still a draft. Present because a
        dry run of the whole pipeline against a throwaway version needs a way to
        clean up after itself."""
        return self._request("DELETE", f"/appStoreVersions/{version_id}")

    # ---- localizations ----------------------------------------------------

    def localizations(self, version_id: str):
        data = self.get_all(
            f"/appStoreVersions/{version_id}/appStoreVersionLocalizations",
            **{"fields[appStoreVersionLocalizations]":
               "locale,whatsNew,promotionalText,description,keywords"})
        return {d["attributes"]["locale"]: d for d in data}

    def update_localization(self, loc_id: str, **attrs):
        body = {"data": {"type": "appStoreVersionLocalizations", "id": loc_id,
                         "attributes": attrs}}
        return self._request("PATCH", f"/appStoreVersionLocalizations/{loc_id}",
                             json=body)

    def create_localization(self, version_id: str, locale: str, **attrs):
        attrs = dict(attrs, locale=locale)
        body = {"data": {
            "type": "appStoreVersionLocalizations", "attributes": attrs,
            "relationships": {"appStoreVersion": {
                "data": {"type": "appStoreVersions", "id": version_id}}},
        }}
        return self._request("POST", "/appStoreVersionLocalizations", json=body)

    # ---- builds -----------------------------------------------------------

    def find_build(self, version_string: str, build_number: str):
        """Match on both the marketing version and the build number. `filter[version]`
        alone matches the build number across every marketing version, and this app
        restarts build numbering, so the pair is what identifies a build."""
        data = self.get_all("/builds", **{
            "filter[app]": APP_ID,
            "filter[preReleaseVersion.version]": version_string,
            "filter[version]": build_number,
            "fields[builds]": "version,processingState,uploadedDate,expired",
        })
        return data[0] if data else None

    def attach_build(self, version_id: str, build_id: str):
        body = {"data": {"type": "builds", "id": build_id}}
        return self._request("PATCH", f"/appStoreVersions/{version_id}/relationships/build",
                             json=body)

    def version_build(self, version_id: str):
        try:
            d = self.get(f"/appStoreVersions/{version_id}/build",
                         **{"fields[builds]": "version,processingState"})
            return d.get("data")
        except ASCError:
            return None

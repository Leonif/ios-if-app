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
    # Added in 1.5.3 (IF-75). Both are new to the listing, not just to the version:
    # the pipeline writes their What's New and promotional text, and nothing else.
    # Name, subtitle, keywords, description and screenshots are the owner's to
    # fill in App Store Connect — see release/README.md, "A new locale".
    "en-US": "en-US",
    "es-MX": "es-MX",
}

# The screenshot set is foldered the way the marketing set was built: `en` and `es`
# without a region, three more under the pack's short names. Every value must be a
# locale of PACK_TO_ASC — release.py refuses a set where the two tables drift apart.
SHOTS_TO_ASC = {
    "en": "en-GB",
    "en-US": "en-US",
    "es-MX": "es-MX",
    "uk": "uk",
    "de": "de-DE",
    "es": "es-ES",
    "fr": "fr-FR",
    "pl": "pl",
    "ja": "ja",
    "ko": "ko",
    "zh-Hans": "zh-Hans",
    "ar": "ar-SA",
}

# 6.7" iPhone, 1290x2796. The only display type the pipeline touches: 6.5", 6.9"
# and iPad sets on the same localization are left as they are.
SCREENSHOT_DISPLAY_TYPE = "APP_IPHONE_67"


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

    def app_info_locales(self) -> set[str]:
        """Locales the listing itself (name, subtitle) exists in.

        Read across every appInfo of the app — the live one and the editable one —
        so a locale counts as known if either carries it. A locale missing from
        all of them is new to the store, and the version-level text this pipeline
        writes is not enough to submit it.
        """
        out = set()
        for info in self.get_all(f"/apps/{APP_ID}/appInfos"):
            for loc in self.get_all(f"/appInfos/{info['id']}/appInfoLocalizations",
                                    **{"fields[appInfoLocalizations]": "locale"}):
                out.add(loc["attributes"]["locale"])
        return out

    # ---- screenshots ------------------------------------------------------

    def screenshot_set(self, loc_id: str, display_type: str = SCREENSHOT_DISPLAY_TYPE):
        for d in self.get_all(f"/appStoreVersionLocalizations/{loc_id}/appScreenshotSets",
                              **{"filter[screenshotDisplayType]": display_type}):
            if d["attributes"]["screenshotDisplayType"] == display_type:
                return d
        return None

    def create_screenshot_set(self, loc_id: str,
                              display_type: str = SCREENSHOT_DISPLAY_TYPE):
        body = {"data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": display_type},
            "relationships": {"appStoreVersionLocalization": {
                "data": {"type": "appStoreVersionLocalizations", "id": loc_id}}},
        }}
        return self._request("POST", "/appScreenshotSets", json=body)["data"]

    def screenshots(self, set_id: str) -> list:
        """The set's screenshots in display order.

        Order is read from the relationship, which is what the store shows; the
        attributes come from the collection and are joined on id.
        """
        order = [d["id"] for d in self.get_all(
            f"/appScreenshotSets/{set_id}/relationships/appScreenshots")]
        attrs = {d["id"]: d for d in self.get_all(
            f"/appScreenshotSets/{set_id}/appScreenshots",
            **{"fields[appScreenshots]":
               "fileName,fileSize,sourceFileChecksum,assetDeliveryState"})}
        return [attrs.get(i, {"id": i, "attributes": {}}) for i in order]

    def screenshot(self, shot_id: str):
        return self.get(f"/appScreenshots/{shot_id}", **{
            "fields[appScreenshots]":
            "fileName,fileSize,sourceFileChecksum,assetDeliveryState"})["data"]

    def delete_screenshot(self, shot_id: str):
        return self._request("DELETE", f"/appScreenshots/{shot_id}")

    def reserve_screenshot(self, set_id: str, file_name: str, file_size: int):
        """Step one of three: App Store Connect answers with where to PUT the bytes."""
        body = {"data": {
            "type": "appScreenshots",
            "attributes": {"fileName": file_name, "fileSize": file_size},
            "relationships": {"appScreenshotSet": {
                "data": {"type": "appScreenshotSets", "id": set_id}}},
        }}
        return self._request("POST", "/appScreenshots", json=body)["data"]

    def upload_parts(self, operations: list, data: bytes):
        """Step two: PUT each slice to Apple's storage. These URLs are pre-signed
        and take no API token."""
        if self.dry_run:
            print(f"  [dry-run] PUT {len(operations)} part(s), {len(data)} bytes")
            return
        for op in operations:
            chunk = data[op["offset"]:op["offset"] + op["length"]]
            headers = {h["name"]: h["value"] for h in op.get("requestHeaders") or []}
            r = requests.request(op["method"], op["url"], headers=headers,
                                 data=chunk, timeout=120)
            if r.status_code >= 400:
                raise ASCError(f"{op['method']} upload part @{op['offset']} -> "
                               f"{r.status_code}\n{r.text[:900]}")

    def commit_screenshot(self, shot_id: str, md5: str):
        """Step three: mark the upload done. Apple checks the bytes against md5."""
        body = {"data": {"type": "appScreenshots", "id": shot_id,
                         "attributes": {"uploaded": True, "sourceFileChecksum": md5}}}
        return self._request("PATCH", f"/appScreenshots/{shot_id}", json=body)

    def order_screenshots(self, set_id: str, shot_ids: list):
        body = {"data": [{"type": "appScreenshots", "id": i} for i in shot_ids]}
        return self._request(
            "PATCH", f"/appScreenshotSets/{set_id}/relationships/appScreenshots",
            json=body)

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

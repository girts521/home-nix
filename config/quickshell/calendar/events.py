#!/usr/bin/env python3
"""Read private iCalendar feeds and return an agenda for a local date range.

No OAuth, GNOME, daemon or credentials in the Nix store. The feed URLs live in
~/.config/quickshell-calendar/feeds (one HTTPS URL per line). Downloaded ICS
files are cached for 300 seconds in a private cache directory.

Usage: qs-calendar-events --start 2026-10-19 --end 2026-11-30
The end date is exclusive. JSON is the only output on stdout.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import sys
import tempfile
import time
from datetime import date, datetime, time as dt_time, timedelta
from urllib.parse import urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

import icalendar
import recurring_ical_events

CACHE_SECONDS = 300
MAX_DOWNLOAD = 15 * 1024 * 1024


class HttpsOnlyRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Don't send a private feed token to a downgraded HTTP redirect.
        if urlsplit(newurl).scheme.lower() != "https":
            raise ValueError("Calendar endpoint requires HTTPS")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def result(status: str, events: list[dict], message: str = "") -> dict:
    return {"status": status, "message": message, "events": events}


def default_feed_path() -> Path:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    return Path(os.environ.get("QS_CALENDAR_FEEDS_FILE", config_home / "quickshell-calendar" / "feeds"))


def default_cache_path() -> Path:
    cache_home = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
    return cache_home / "quickshell-calendar"


def read_feeds(path: Path) -> list[str]:
    if not path.exists():
        return []
    # A private Google ICS URL is equivalent to a read-only access credential.
    if stat.S_IMODE(path.stat().st_mode) & 0o077:
        raise ValueError("Set calendar feed file permissions to 600 (chmod 600).")
    feeds = []
    for raw in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = urlsplit(line)
        if parts.scheme != "https" or not parts.netloc:
            raise ValueError("Calendar feed URLs must use HTTPS.")
        feeds.append(line)
    return feeds


def download_or_cache(url: str, cache_dir: Path) -> tuple[bytes | None, str]:
    cache_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(cache_dir, 0o700)
    cache_file = cache_dir / (hashlib.sha256(url.encode()).hexdigest() + ".ics")

    def old_cache() -> bytes | None:
        try:
            return cache_file.read_bytes()
        except OSError:
            return None

    try:
        if time.time() - cache_file.stat().st_mtime < CACHE_SECONDS:
            contents = old_cache()
            if contents:
                return contents, "cached"
    except FileNotFoundError:
        pass

    try:
        req = Request(url, headers={"User-Agent": "qs-calendar-events/1.0", "Accept": "text/calendar"})
        with build_opener(HttpsOnlyRedirects()).open(req, timeout=8) as response:
            # Never follow a redirect to an unencrypted connection.
            if urlsplit(response.geturl()).scheme != "https":
                raise ValueError("Calendar endpoint requires HTTPS")
            body = response.read(MAX_DOWNLOAD + 1)
        if len(body) > MAX_DOWNLOAD or not body.lstrip().startswith(b"BEGIN:VCALENDAR"):
            raise ValueError("Invalid or oversized calendar response")
        # Only atomically replace a good-looking ICS feed, preserving stale data
        # if the request fails. Directory and cache files are private.
        fd, temp_name = tempfile.mkstemp(prefix=".ics-", dir=cache_dir)
        try:
            with os.fdopen(fd, "wb") as f:
                f.write(body)
            os.chmod(temp_name, 0o600)
            os.replace(temp_name, cache_file)
        finally:
            if os.path.exists(temp_name):
                os.unlink(temp_name)
        return body, "fresh"
    except (OSError, ValueError):
        old = old_cache()
        if old:
            return old, "stale"
        return None, "unavailable"


def local_datetime(value: date | datetime) -> datetime:
    if isinstance(value, datetime):
        # astimezone() handles local DST for the event's actual timestamp.
        return value.astimezone()
    # Noon is safe even on unusual daylight-saving transition dates.
    return datetime.combine(value, dt_time(12, 0)).astimezone()


def expand_events(ics: bytes, start_day: date, end_day: date) -> list[dict]:
    calendar = icalendar.Calendar.from_ical(ics)
    start_bound = datetime.combine(start_day, dt_time.min).astimezone()
    end_bound = datetime.combine(end_day, dt_time.min).astimezone()
    rows = []

    # Expands RRULE/RDATE/EXDATE and RECURRENCE-ID overrides, including edits to
    # instances of a recurring Google Calendar event.
    for event in recurring_ical_events.of(calendar).between(start_bound, end_bound):
        if str(event.get("STATUS", "")).upper() == "CANCELLED":
            continue
        if "DTSTART" not in event:
            continue

        start_value = event.decoded("DTSTART")
        if "DTEND" in event:
            end_value = event.decoded("DTEND")
        elif "DURATION" in event:
            end_value = start_value + event.decoded("DURATION")
        else:
            end_value = start_value + (timedelta(days=1) if not isinstance(start_value, datetime)
                                       else timedelta(minutes=1))

        all_day = not isinstance(start_value, datetime)
        start_dt = local_datetime(start_value)
        end_dt = local_datetime(end_value)
        if end_dt <= start_dt:
            end_dt = start_dt + timedelta(minutes=1)

        if all_day:
            # Date-only DTEND is *exclusive* in iCalendar. An event with
            # DTSTART=Oct 20 and DTEND=Oct 21 belongs only to Oct 20.
            first = max(start_value, start_day)
            last = min(end_value - timedelta(days=1), end_day - timedelta(days=1))
        else:
            first = max(start_dt.date(), start_day)
            last = min((end_dt - timedelta(microseconds=1)).date(), end_day - timedelta(days=1))
        if first > last:
            continue

        title = str(event.get("SUMMARY", "Untitled event"))[:180]
        location = str(event.get("LOCATION", ""))[:180]
        day = first
        while day <= last:
            if all_day:
                time_label = "All day"
                sorting = "00:00"
            elif day == start_dt.date():
                time_label = start_dt.strftime("%H:%M")
                sorting = start_dt.strftime("%H:%M")
            elif day == last:
                time_label = "Until " + end_dt.strftime("%H:%M")
                sorting = "00:01"
            else:
                time_label = "Continues"
                sorting = "00:01"

            rows.append({
                "day": day.isoformat(),
                "title": title,
                "time": time_label,
                "allDay": all_day,
                "location": location,
                "sort": ("0" if all_day else "1") + sorting,
            })
            day += timedelta(days=1)
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--start", required=True, help="First local day (YYYY-MM-DD)")
    parser.add_argument("--end", required=True, help="Exclusive last local day (YYYY-MM-DD)")
    args = parser.parse_args()

    try:
        start_day = date.fromisoformat(args.start)
        end_day = date.fromisoformat(args.end)
        if not start_day < end_day or (end_day - start_day).days > 62:
            raise ValueError("Please request a range of 1 to 62 days.")
        feeds = read_feeds(default_feed_path())
        if not feeds:
            print(json.dumps(result("unconfigured", [], "Add an ICS URL to ~/.config/quickshell-calendar/feeds")))
            return 0

        rows = []
        states = []
        for url in feeds:
            contents, state = download_or_cache(url, default_cache_path())
            states.append(state)
            if contents:
                try:
                    rows.extend(expand_events(contents, start_day, end_day))
                except Exception:
                    states[-1] = "unavailable"

        rows.sort(key=lambda ev: (ev["day"], ev["sort"], ev["title"].lower()))
        # Don't leak private feed URLs or event details to stderr or journals.
        if "unavailable" in states:
            status, message = "partial", "One or more calendar feeds could not be loaded."
        elif "stale" in states:
            status, message = "stale", "Offline or unavailable; showing saved events."
        else:
            status, message = "ok", ""
        print(json.dumps(result(status, rows, message), ensure_ascii=False))
        return 0
    except ValueError as exc:
        print(json.dumps(result("error", [], str(exc))))
        return 1
    except Exception:
        print(json.dumps(result("error", [], "Could not read calendar data.")))
        return 1


if __name__ == "__main__":
    sys.exit(main())

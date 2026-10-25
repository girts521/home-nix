#!/usr/bin/env python3
"""Fetch current Berlin weather from Open-Meteo and print compact JSON."""
import json
import urllib.request

URL = "https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.405&current=temperature_2m,weather_code,is_day&timezone=Europe%2FBerlin"
request = urllib.request.Request(URL, headers={"User-Agent": "home-nix-quickshell-bar/1.0"})
with urllib.request.urlopen(request, timeout=8) as response:
    data = json.load(response)["current"]
print(json.dumps({"temperature": round(data["temperature_2m"]), "code": int(data["weather_code"]), "isDay": bool(data["is_day"])}))

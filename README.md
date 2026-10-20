# Quickshell / Niri calendar (Home Manager)

This bundle extends the existing shared `bar` Quickshell configuration. It was
prepared from the last working 3-monitor Niri bar discussed in chat (animated
workspace indicators, CPU/RAM, pywal colors).

## Files

- `config/quickshell/bar/shell.qml` — current bar, with the date click changed
  from `gnome-calendar` to `calendarPopup.toggle()`; imports `components` and
  instantiates one `CalendarPopup` per output.
- `config/quickshell/bar/components/CalendarPopup.qml` — month view, mouse
  wheel / arrow navigation, Today shortcut, selected-day agenda, subtle fades,
  live pywal colors.
- `config/quickshell/calendar/events.py` — independent ICS reader/5-minute
  offline cache. It expands recurring events with `recurring-ical-events`.
- `home/modules/quickshell.nix` — installs Quickshell and `qs-calendar-events`
  through Nix; keeps the existing graphical-session systemd user service.

**Important:** extracting the ZIP overwrites the existing `shell.qml` and
`home/modules/quickshell.nix`. If you've customized those files since the
previous version, compare or back them up first. All of the other files are
new. The secret feed URL is NOT part of this package.

## 1. Add the files to home-nix

```bash
cd ~/dev/home-nix
unzip ~/Downloads/quickshell-calendar-home-nix.zip -d .
git add config/quickshell home/modules/quickshell.nix
home-manager switch --flake .#laptop
```

Your `flake.nix` already imports `./home/modules/quickshell.nix` for the laptop;
no additional flake changes are needed.

## 2. Create a PRIVATE local calendar feed file

In Google Calendar (web): Settings > choose calendar > Integrate calendar >
**Secret address in iCal format**. Copy this *private subscription URL*, not a
one-time ICS export. Some organization calendars have this disabled by policy.

```bash
install -d -m 700 ~/.config/quickshell-calendar
umask 077
nano ~/.config/quickshell-calendar/feeds
chmod 600 ~/.config/quickshell-calendar/feeds
```

Put ONE HTTPS iCal URL on each line. You may list more than one calendar. The
private feed URLs must never be committed to Git, put in Nix config, or shared.
The helper refuses to read the URL file if it is group/world-readable.

## 3. Test backend independently

```bash
qs-calendar-events --start "$(date +%F)" --end "$(date -d '+35 days' +%F)" | jq
```

Expected output is JSON with `status` and `events`. The `day` field contains
local dates. The helper caches each full ICS feed for **300 seconds** under
`~/.cache/quickshell-calendar/` with restrictive permissions; if the network
is unavailable, it uses the previously cached feed and reports `stale`. Note
that Google may refresh its ICS feed at its own cadence, independent of the
five-minute local cache.

## 4. Launch / refresh bar

If using Home Manager's service:

```bash
systemctl --user restart quickshell.service
journalctl --user -u quickshell.service -n 40 --no-pager
```

Click the date in the top bar. The popup works on any of your three monitors.
Arrow buttons and **scrolling over the month grid** change months; click any
day to see its agenda. **Today** returns to the current date. Clicking outside
closes the popup.

## Development

You can edit the source files in your repo, then test hot-reload directly:

```bash
qs -p ~/dev/home-nix/config/quickshell/bar
```

Stop the systemd-managed bar first if you do this to avoid duplicate bars:

```bash
systemctl --user stop quickshell.service
```

Then use `home-manager switch --flake .#laptop` and start the service again
when ready.

## Notes

- No GNOME services, OAuth credentials, Google Cloud project, or extra daemon.
- Read-only; creating/editing events still requires Google Calendar or another
  calendar client.
- Calendar feeds can be disabled by Google Workspace administrators.
- The helper binary is installed in the Home Manager profile. The QML component
  calls `~/.nix-profile/bin/qs-calendar-events` to work even if the systemd
  environment's PATH is minimal.
- There is one lightweight `PopupWindow` per screen, but **no calendar process
  is running while the popup is closed**.

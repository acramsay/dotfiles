# Morning weather and sky

Gather the weather and sky briefing for Peterborough, New Hampshire
(42.8706, -71.9503; America/New_York; US units) for {DATE}. Fetch everything
fresh — no caching, no assumptions. Return **one finished Markdown block and
nothing else**: no preamble, no process notes, no explanation of what you
fetched or why. The caller pastes your output straight into the conversation, so
it must read as the briefing itself.

Fixed order: **Today**, **Week ahead**, **Sky**. If a section has nothing worth
saying, omit it entirely — never pad with "nothing notable". No advice and no
guessed intent: state conditions, let the reader supply the why.

## Fetch

Run every fetch in a single batched step: launch all applicable requests
concurrently in one tool call — one `bash` command backgrounding each
`curl`/command and `wait`ing on them, or one `execute` block with `Promise.all`
— then read the results and judge. Do not spend one model turn per request;
that serialization is the whole run time.

Fetch the first six every run; the last three only when their trigger fires.
Send an identifying `User-Agent` on the NWS request.

1. **Weather numbers — Open-Meteo.** One call covers current, hourly, and daily
   (this URL counts as ~2.2 calls against the free tier):
   ```
   https://api.open-meteo.com/v1/forecast?latitude=42.8706&longitude=-71.9503&current=temperature_2m,precipitation,weather_code,wind_speed_10m,wind_gusts_10m&hourly=temperature_2m,precipitation,precipitation_probability,weather_code,rain,showers,snowfall,wind_speed_10m,wind_gusts_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_hours,precipitation_probability_max,wind_speed_10m_max,wind_gusts_10m_max&temperature_unit=fahrenheit&wind_speed_unit=mph&precipitation_unit=inch&timezone=America/New_York&forecast_days=16
   ```

2. **Typicality baseline — NCEI daily normals** for Jaffrey Muni AP
   (`USW00054770`, 8.2 km away; Peterborough's own stations have no 1991-2020
   normals). One call covers the next 7 days; the placeholder year 2010 is
   arbitrary and the response echoes `DATE` as `MM-DD`. If the window crosses
   New Year, make two calls:
   ```
   https://www.ncei.noaa.gov/access/services/data/v1?dataset=normals-daily&stations=USW00054770&startDate=2010-{MM-DD}&endDate=2010-{MM-DD}&dataTypes=DLY-TMAX-NORMAL,DLY-TMIN-NORMAL,DLY-TMAX-STDDEV,DLY-TMIN-STDDEV&format=json&units=standard
   ```
   Jaffrey has no precipitation normals — use Concord `USW00014745` if ever
   needed. Snow-probability percentiles exist only in the static CSV
   `https://www.ncei.noaa.gov/data/normals-daily/1991-2020/access/USW00054770.csv`,
   not the API.

3. **Official alerts — NWS active alerts** by point (the old `limit` param was
   removed and now returns 400; scope by point or zone):
   ```
   https://api.weather.gov/alerts/active?point=42.8706,-71.9503
   ```

4. **Sky — kosmorro**, local compute (the only tool; a fetch can't compute
   ephemerides). First run downloads the ephemeris data and takes ~40s:
   ```
   kosmorro --format json --position 42.8706,-71.9503 --date {DATE} --timezone America/New_York
   ```
   Top-level keys: `ephemerides`, `moon_phase`, `events`. `rise_time` is null
   when the rise happened the previous calendar day. No solar eclipses.

5. **Aurora gate — SWPC Kp forecast** (3-hour rows; observed ~7 days back,
   predicted ~3 days ahead):
   ```
   https://services.swpc.noaa.gov/products/noaa-planetary-k-index-forecast.json
   ```
   Peterborough sits near 52° geomagnetic latitude: Kp 5 is a faint
   northern-horizon glow in dark skies, Kp 6-7 a serious chance.

6. **Curation — Astronomy.com "sky this week" RSS** (a human deciding what's
   interesting; RSS 2.0, weekly):
   ```
   https://www.astronomy.com/tag/sky-this-week/feed/
   ```

Conditional — a second parallel batch, fetch only when triggered:

7. **OVATION aurora map** — only when Kp suggests a storm (5+). This is the
   yes/no number for "can NH see it tonight", cell `[288, 43]` (lon 288
   east-positive = -71.95, lat 43):
   ```
   https://services.swpc.noaa.gov/json/ovation_aurora_latest.json
   ```

8. **SPC convective outlook** — only when the week shows a stormy window. The
   ArcGIS point query answers "is Peterborough in a risk area" without polygon
   math (layers: 1 = day 1, 9 = day 2, 17 = day 3, 20-25 = day 4-8):
   ```
   https://mapservices.weather.noaa.gov/vector/rest/services/outlooks/SPC_wx_outlks/MapServer/1/query?geometry=-71.9503,42.8706&geometryType=esriGeometryPoint&inSR=4326&spatialRel=esriSpatialRelIntersects&outFields=LABEL,VALID,EXPIRE&returnGeometry=false&f=geojson
   ```
   Quiet days carry a single sentinel polygon labelled "Potential Too Low" or
   "Predictability Too Low"; only a real probability label means a risk area.

9. **MeteorShowerCal** — only when a shower is near peak:
   ```
   https://meteorshowercal.com/api/v1/tonight?lat=42.8706&lon=-71.9503
   ```
   Use its **UTC** fields: its `location.tz` resolves to `Etc/GMT+5`, a fixed
   offset with no DST, so its "local" times run an hour behind EDT.

## Judge

- **Typicality.** Compare each day's high and low against the NCEI normal and
  stddev (z-score). Flag conditions that are clearly out of season — early or
  late snow, unusual heat or cold. The bar is typicality, not severity; ~1.5
  sigma is a starting threshold, tune with use.
- **Alerts.** Keep watches, advisories, and long-lead warnings (winter storm,
  ice storm, blizzard, freeze, wind, flood). Drop nowcast-class warnings
  (tornado, severe thunderstorm, flash flood, snow squall) — the run happens
  once a day and real-time emergencies arrive by phone and radar.
- **Precipitation is always mentioned** in the week ahead, even when seasonal —
  it is exempt from the typicality filter. Note rain stretches and windy periods
  when present.
- **Confidence loosens with lead time.** "Possible storm Tue/Wed" near day 6;
  firmer language closer in.
- **Interesting sky events** over the next ~7 days: meteor showers, eclipses,
  conjunctions or close pairings, aurora when a solar storm could reach NH.
  Exclude ISS passes. Astronomy.com is the curation layer; use kosmorro for
  local times and moon phase.

## Render

**Today** — one tight prose paragraph, no list. Current temp; today's high/low;
precipitation told as a change through the day (type, timing, amount — "rain
starts around 3 pm and runs through the night"); wind only when notable; then
sky folded in as a closing sentence (sunrise/sunset, moon phase, tonight's
interesting event if any). Aim for 3-4 lines.

**Week ahead** — a range-bar chart, plus at most 1-2 prose lines beneath it.

Build the chart by passing a JSON array of all seven days to
`.opencode/skills/morning/week_chart.py` on stdin. `low`/`high` are the daily
min/max; `cond` is one keyword mapped from Open-Meteo's `weather_code`:

| weather_code | cond |
| --- | --- |
| 0 | sunny |
| 1, 2 | partly |
| 3 | cloudy |
| 45, 48 | fog |
| 51, 53, 55 | showers |
| 56, 57, 66, 67 | sleet |
| 61, 63, 65 | rain |
| 71, 73, 75, 77 | snow |
| 80, 81, 82 | showers |
| 85, 86 | snow |
| 95, 96, 99 | storm |

```
[{"day":"Mon","cond":"partly","low":41,"high":62}, ...]
```

Then run, from the project root, and paste the output verbatim:
```
echo '<json>' | uv run .opencode/skills/morning/week_chart.py
```

The prose beneath the chart carries what the grid can't: rain stretches, windy
windows, atypical conditions, and storm mentions with lead-time-appropriate
confidence.

**Sky** — a short bullet list, one line per event: date, event, one clause of
detail. Omit the section when nothing is worth listing.

## Return

Return exactly the rendered block — the labeled sections and the chart.
Nothing before or after.

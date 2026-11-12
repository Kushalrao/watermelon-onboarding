import json, sys, urllib.request, urllib.parse, datetime, concurrent.futures as cf

FUNDS = [
 ("Axis Small Cap","axis small cap"),("Nippon India Small Cap","nippon india small cap"),("SBI Small Cap","sbi small cap"),
 ("Quant Small Cap","quant small cap"),("HDFC Small Cap","hdfc small cap"),("Kotak Small Cap","kotak small cap"),
 ("DSP Small Cap","dsp small cap"),("Tata Small Cap","tata small cap"),("Axis Midcap","axis midcap"),
 ("HDFC Mid Cap","hdfc mid"),("Kotak Emerging Equity","kotak emerging equity"),("Motilal Oswal Midcap","motilal oswal midcap"),
 ("PGIM India Midcap","pgim india midcap"),("Nippon India Growth","nippon india growth"),("SBI Magnum Midcap","sbi magnum midcap"),
 ("Edelweiss Mid Cap","edelweiss mid cap"),("DSP Midcap","dsp midcap"),("Axis Large Cap","axis bluechip"),
 ("Mirae Asset Large Cap","mirae asset large cap"),("ICICI Pru Large Cap","icici prudential bluechip"),("SBI Large Cap","sbi large cap"),
 ("HDFC Large Cap","hdfc large cap"),("Nippon India Large Cap","nippon india large cap"),("Kotak Large Cap","kotak large cap"),
 ("Canara Robeco Large Cap","canara robeco large cap"),("Parag Parikh Flexi Cap","parag parikh flexi cap"),("HDFC Flexi Cap","hdfc flexi cap"),
 ("Kotak Flexicap","kotak flexi"),("UTI Flexi Cap","uti flexi cap"),("PGIM India Flexi Cap","pgim india flexi cap"),
 ("Quant Flexi Cap","quant flexi cap"),("SBI Contra","sbi contra"),("Invesco India Contra","invesco india contra"),
 ("Kotak Contra","kotak contra"),("ICICI Pru Value","icici prudential value discovery"),("Nippon India Value","nippon india value"),
 ("HDFC Balanced Advantage","hdfc balanced advantage"),("ICICI Pru Balanced Advantage","icici prudential balanced advantage"),
 ("Mirae Asset ELSS","mirae asset elss"),("Axis ELSS","axis elss"),("Quant ELSS","quant elss"),
 ("ICICI Pru Technology","icici prudential technology"),("SBI Healthcare","sbi healthcare opportunities"),
 ("Nippon India Pharma","nippon india pharma"),("ICICI Pru Infrastructure","icici prudential infrastructure"),
 ("Quant Infrastructure","quant infrastructure"),("UTI Nifty 50 Index","uti nifty 50 index"),("HDFC Nifty 50 Index","hdfc nifty 50 index"),
 ("Motilal Oswal Nasdaq 100","motilal oswal nasdaq 100"),("SBI Gold","sbi gold fund"),
 ("Bandhan Small Cap","bandhan small cap"),("Franklin India Flexi Cap","franklin india flexi cap"),
 ("Mirae Asset Midcap","mirae asset midcap"),("ICICI Pru Midcap","icici prudential midcap"),
]

import time, os
def get(url):
    for attempt in range(6):
        try:
            with urllib.request.urlopen(url, timeout=30) as r:
                time.sleep(1.2)
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            if e.code == 429:
                time.sleep(5 * (attempt + 1)); continue
            raise
    raise RuntimeError("rate limited")

def pick(query):
    res = get("https://api.mfapi.in/mf/search?q=" + urllib.parse.quote(query))
    good = [x for x in res if "direct" in x["schemeName"].lower() and "growth" in x["schemeName"].lower()
            and not any(b in x["schemeName"].lower() for b in ["idcw","dividend","bonus","payout","reinvest"])]
    return good[0] if good else None

def sample(points, start, n):
    win = [(d, v) for d, v in points if d >= start]
    if len(win) < 2: return None
    out = []
    for i in range(n):
        out.append(win[round(i * (len(win) - 1) / (n - 1))])
    return out

def build(entry):
    name, q = entry
    try:
        s = pick(q)
        if not s: return name, None, "no direct growth match"
        data = get(f"https://api.mfapi.in/mf/{s['schemeCode']}")
        pts = []
        for row in data["data"]:
            try:
                d = datetime.datetime.strptime(row["date"], "%d-%m-%Y").date(); v = float(row["nav"])
                if v > 0: pts.append((d, v))
            except Exception: pass
        pts.sort()
        last_d, last_v = pts[-1]
        y1 = sample(pts, last_d - datetime.timedelta(days=365), 48)
        y5 = sample(pts, last_d - datetime.timedelta(days=365*5), 60)
        if not y1: return name, None, "too short"
        five_full = y5 is not None and y5[0][0] <= last_d - datetime.timedelta(days=365*5-10)
        out = {
            "name": name, "scheme": s["schemeName"], "code": s["schemeCode"],
            "asOf": last_d.isoformat(), "nav": round(last_v, 2),
            "oneYear": {"from": y1[0][0].isoformat(), "navs": [round(v, 2) for _, v in y1]},
            "fiveYear": {"from": y5[0][0].isoformat(), "navs": [round(v, 2) for _, v in y5], "full": five_full} if y5 else None,
        }
        return name, out, None
    except Exception as e:
        return name, None, str(e)

existing = json.load(open(sys.argv[1]))["funds"] if os.path.exists(sys.argv[1]) else []
have = {f["name"] for f in existing}
results = [build(e) for e in FUNDS if e[0] not in have]
funds = existing + [o for _, o, _ in results if o]
order = {n: i for i, (n, _) in enumerate(FUNDS)}
funds.sort(key=lambda f: order.get(f["name"], 999))
for n, o, err in results:
    if err: print("SKIP", n, err, file=sys.stderr)
json.dump({"source": "api.mfapi.in (AMFI NAV history)", "fetched": datetime.date.today().isoformat(), "funds": funds},
          open(sys.argv[1], "w"), separators=(",", ":"))
print(len(funds), "funds")

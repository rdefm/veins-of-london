"""PROTOTYPE: static selected-direction board; illustrative values, no game logic."""

from pathlib import Path
from static_concepts import CSS, chart

ROOT = Path(__file__).parent

CSS += r"""
.selected{--bg:#101923;--ink:#fbfaf6;--head:#172431;--head-ink:#fbfaf6;--status:#172431;--status-ink:#fbfaf6;--nav:#172431;--card:#1b2a38;--line:#354454;--muted:#a9b5bd;--accent:#e9353c;--accent-ink:#fffaf7;--soft:#2b3b4b;--alert:#ff777a;--alert-soft:#3b2935;--ok:#b4d6c2;--ok-soft:#2b403e;--other:#8ca0ad;--shadow:none}
.selected .app-head{padding:13px 17px 10px;border-bottom:1px solid var(--line)}
.selected .brandline{justify-content:flex-start;gap:9px}.selected .brand-icon{width:30px;height:30px;border-radius:7px;object-fit:cover}
.selected .brand{font:700 24px/1 Georgia,serif;letter-spacing:-.055em}.selected .brand em{color:#fbfaf6}
.selected .day{margin-left:auto;font-size:9px}.selected .subhead{margin-left:39px;margin-top:1px}
.selected .nav{padding:4px 7px 0;gap:0}.selected .nav span{border-radius:0;background:none;padding:10px 2px 11px;font-size:11px;text-transform:uppercase;letter-spacing:.06em}
.selected .nav .on{color:#fff;border-bottom:3px solid var(--accent);background:none}
.selected .body{padding:14px 13px 65px}.selected .card{border-radius:6px}.selected .card.hero{background:#1e3040;border-left:3px solid var(--accent)}
.selected .section-title{font:400 17px/1.12 Georgia,serif;letter-spacing:-.015em;color:#fbfaf6;margin:15px 0 9px}
.selected .section-title small{font:700 9px/1 Arial,sans-serif;letter-spacing:.1em;text-transform:uppercase;color:#a9b5bd}
.selected .value{font:500 25px/1 Georgia,serif;letter-spacing:-.03em}.selected .button{border-radius:4px}
.selected .chip{border-radius:3px}.selected .chip.ok{color:#b4d6c2}.selected .notice{border-left-color:var(--accent)}
.selected .bottom-safe{background:var(--bg)}
.selected .contract-split{font-size:10px;font-weight:800;letter-spacing:.13em;text-transform:uppercase;color:#c6d0d5;margin:13px 0 7px;display:flex;align-items:center;justify-content:space-between}
.selected .contract-split b{color:#ff898a;font-size:9px}.selected .subtle-link{font-size:10px;color:#ff898a;font-weight:700}
.selected .role-tag{font-size:9px;text-transform:uppercase;letter-spacing:.11em;color:#d8e4e8}
.selected .alert-action{background:#e9353c;color:#fff}.selected .minor{font-size:10px;color:#a9b5bd}
.selected .flow{display:flex;gap:5px}.selected .flow span{flex:1;text-align:center;background:#283949;border:1px solid #354454;border-radius:4px;padding:6px 2px;font-size:9px;font-weight:700;color:#ccd6dc}
.selected .flow .current{background:#e9353c;color:#fff;border-color:#e9353c}
"""

BRIEF = '''<div class="kicker">Account / Day 24 / Morning</div><div class="card hero"><div class="row"><div><div class="label">CLOSING / REYNARD'S</div><div class="value mono">£1,840</div></div><div style="text-align:right"><div class="chip ok">+£430</div><div class="small" style="margin-top:5px">NET CHANGE</div></div></div></div>
<div class="metric-grid"><div class="card tight"><div class="label">INCOME</div><div class="strong mono">+£640</div></div><div class="card tight"><div class="label">EXPENSES</div><div class="strong mono">−£210</div></div></div>
<div class="section-title">Needs your attention <small>02 OPEN</small></div><div class="card tight"><div class="row"><span class="chip alert">DUE TODAY</span><span class="small">01 / ALARMS</span></div><div class="strong" style="margin-top:9px">Whitechapel raid</div><div class="small">Intervention closes at end of day</div><div class="divider"></div><div class="row"><span class="small">Review the rolled consequence</span><span class="button">REVIEW →</span></div></div>
<div class="card tight"><div class="row"><div><div class="strong">Unread message · Archie</div><div class="small">02 / Messages</div></div><span class="button quiet">OPEN →</span></div></div>
<div class="section-title">Treasury <small>MOVE FUNDS →</small></div><div class="card tight"><div class="row"><span>Business pot</span><b>£1,220</b></div><div class="divider"></div><div class="row"><span>Bill float</span><b>£340</b></div></div><div class="section-title">Operations feed <small>FULL BRIEF →</small></div><div class="lineitem"><span>TIME ORE / PRODUCED</span><b>+12</b></div><div class="lineitem"><span>PEARLS / MADE</span><b>+5</b></div><div class="lineitem"><span>GUARD WAGES / PAID</span><b>−£80</b></div>'''

MANAGE = '''<div class="kicker">Operations / Sales pipeline</div><div class="card hero"><div class="row"><div><div class="label">SALES PIPELINE</div><div class="value">2 active</div></div><span class="chip">1 OFFER</span></div><div class="divider"></div><div class="small">Sales delivers from shared stock at block end.</div></div>
<div class="contract-split">Offered contracts <b>01 NEW</b></div><div class="card"><div class="row"><span class="chip">WEEKLY OFFER</span><span class="small">Expires Day 27</span></div><div class="strong" style="margin:10px 0 3px">The Guild · 6 Time ore</div><div class="small">Recurring order · £360 per delivery</div><div class="divider"></div><div class="row"><span class="value mono">£360</span><div><span class="button quiet">Decline</span> <span class="button">Accept</span></div></div></div>
<div class="contract-split">Accepted contracts <span class="subtle-link">HISTORY →</span></div><div class="card tight"><div class="row"><span class="strong">≡ 01 · Stepney order</span><span class="chip ok">ACTIVE</span></div><div class="small">The Guild · 4 / 6 Time ore · due Day 26</div><div class="progress"><i></i></div><div class="row"><span class="small">Buy missing calc: off</span><span class="subtle-link">DETAILS →</span></div></div><div class="card tight"><div class="row"><span class="strong">≡ 02 · Pearl order</span><span class="chip ok">ACTIVE</span></div><div class="small">3 / 5 Time pearls · due Day 28</div><div class="progress"><i style="width:60%"></i></div><div class="small">Drag cards to set delivery priority.</div></div>
<div class="section-title">Production <small>LOG →</small></div><div class="card tight"><div class="row"><div><div class="strong">Time pearl</div><div class="small">Personal target 5 · contract need 3</div></div><span class="step"><b>−</b><b>5</b><b>+</b></span></div><div class="divider"></div><div class="row"><span class="small">Cover contract needs</span><span class="chip ok">ON</span></div></div>
<div class="section-title">Procurement <small>ASSIGN VEINS →</small></div><div class="card tight"><div class="row"><div><div class="strong">Owen · Cultivation</div><div class="small">Whitechapel — Time</div></div><span class="step"><b>−5</b><b>10</b><b>+5</b></span></div></div>'''

STAFF = '''<div class="kicker">Roster / 02 Recruited</div><div class="card hero"><div class="row"><div><div class="label">PAYROLL EXPOSURE</div><div class="value mono">£40 owed</div></div><span class="chip alert">ACTION</span></div></div>
<div class="section-title">01 / Owen</div><div class="card"><div class="row"><div class="person"><span class="avatar">OW</span><div><div class="role-tag">Cultivation</div><div class="small">Unpaid · 15% remainder</div></div></div><span class="chip alert">DUE</span></div><div class="divider"></div><div class="lineitem"><span>CULTIVATING</span><b>LV 4 / 18 XP</b></div><div class="lineitem"><span>PRODUCTION</span><b>LV 2 / 6 XP</b></div><div class="row" style="margin-top:11px"><span class="button quiet">ROLE ▾</span><span class="button">PAY £40 →</span></div></div>
<div class="section-title">02 / James</div><div class="card"><div class="row"><div class="person"><span class="avatar">JA</span><div><div class="role-tag">Production</div><div class="small">Working · 20% remainder</div></div></div><span class="chip ok">CLEAR</span></div><div class="divider"></div><div class="lineitem"><span>CRAFTING</span><b>LV 5 / 22 XP</b></div><div class="row" style="margin-top:11px"><span class="button quiet">ROLE ▾</span><span class="small">DETAILS →</span></div></div><div class="section-title">Assignments</div><div class="card tight"><div class="row"><span>Vein picking</span><span class="small">MANAGE / PROCUREMENT →</span></div></div>'''

STATS = '''<div class="kicker">Performance / 10-day window</div><div class="card hero"><div class="row"><div><div class="label">REVENUE</div><div class="value mono">£3,460</div></div><div style="text-align:right"><div class="label">EXPENSES</div><div class="strong mono">£1,180</div></div></div></div><div class="section-title">Daily trend</div><div class="card tight">'''+chart(second=True)+'''<div class="legend"><span><i class="dot"></i>REVENUE</span><span><i class="dot other"></i>EXPENSES</span></div></div><div class="section-title">Expense analysis <small>GUARD DETAIL →</small></div><div class="card tight"><div class="lineitem"><span>STAFF WAGES</span><b>£590</b></div><div class="lineitem"><span>GUARD WAGES ↗</span><b>£420</b></div><div class="lineitem"><span>CALC BOUGHT</span><b>£170</b></div></div><div class="section-title">Ore yield <small>COLLECTION SOURCE</small></div><div class="tabs-mini" style="margin-bottom:9px"><span class="selected">CULTIVATORS</span><span>YOU</span></div><div class="card tight">'''+chart()+'''</div><div class="section-title">Items produced</div><div class="card tight"><div class="row"><span>10-DAY TOTAL</span><b>18</b></div></div>'''

screens = [('Brief',BRIEF),('Manage',MANAGE),('Staff',STAFF),('Stats',STATS)]
phones = ''
for tab,content in screens:
    nav = ''.join(f'<span class="{"on" if name == tab else ""}">{name}</span>' for name,_ in screens)
    phones += f'''<div><div class="phone-label">{tab}</div><div class="phone"><div class="screen selected"><div class="status"><span>08:14</span><span class="bars">▂▄▆ &nbsp; ◉ &nbsp; ▰ 87%</span></div><div class="app-head"><div class="back">‹ Phone</div><div class="brandline"><img class="brand-icon" src="../../assets/phone/icons/bizbrief.png" alt=""><div class="brand">Biz<em>Brief</em></div><div class="day">Day 24 · Morning</div></div><div class="subhead">Business, under control.</div></div><div class="nav">{nav}</div><div class="body">{content}</div><div class="bottom-safe"></div></div></div></div>'''

HTML = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=1740"><title>BizBrief — Selected static direction</title><style>{CSS}</style></head><body><main class="board"><header class="board-head"><div><div class="eyebrow">BizBrief · static direction / round 2</div><h1>Control Room × Private Office</h1><p class="board-desc">Icon navy, paper white, and signal red · darker business console · editorial headings and figures.</p></div><div class="board-note">Illustrative values · established game actions only<br>Brief / Manage / Staff / Stats · phone-sized views</div></header><div class="phones">{phones}</div></main></body></html>'''
(ROOT / 'selected-direction.html').write_text(HTML, encoding='utf-8')
print(ROOT / 'selected-direction.html')

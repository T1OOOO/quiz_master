"""Render blind candidate, editorial key, provenance ledger and closed JSON from checkpoints."""
from __future__ import annotations
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).parent
PAT = re.compile(r"^## (compositions\d{3}) · (.+?) · позиция ([ABCD])$(.*?)(?=^## |\Z)", re.M | re.S)
items=[]
for p in sorted(ROOT.glob("compositions20-checkpoint-*.md")):
  for ident,title,pos,body in PAT.findall(p.read_text(encoding="utf-8")):
    q=re.search(r"\n\n(.+?)\n\nA\. ",body,re.S).group(1).replace("\n"," ")
    opts=dict(re.findall(r"^([ABCD])\. (.+)$",body,re.M))
    ans=re.search(r"^\*\*Ответ:\*\* ([ABCD])\. (.+)$",body,re.M)
    exp=re.search(r"^\*\*Объяснение \([^)]*\):\*\* (.+)$",body,re.M).group(1)
    src=re.search(r"^\*\*Источники:\*\* (.+)$",body,re.M).group(1)
    items.append({"id":ident,"title":title,"position":pos,"question":q,"options":opts,"answer":ans.group(1),"answer_text":ans.group(2),"explanation":exp,"sources":src})
assert len(items)==20 and [x['id'] for x in items]==[f"compositions{i:03d}" for i in range(1,21)]
assert {x['position'] for x in items}==set('ABCD') and all(sum(x['position']==k for x in items)==5 for k in 'ABCD')
outputs = {
  "compositions20-candidate.md": '# Compositions20 — candidate (blind)\n\n'+''.join(f"## {x['id']} · {x['title']}\n\n{x['question']}\n\n"+''.join(f"{k}. {v}\n" for k,v in x['options'].items())+'\n' for x in items),
  "compositions20-editorial-key.md": '# Compositions20 — editorial key\n\n'+''.join(f"## {x['id']} · {x['title']}\n\n**Ответ:** {x['answer']}. {x['answer_text']}\n\n**Объяснение:** {x['explanation']}\n\n**Источники:** {x['sources']}\n\n" for x in items),
  "compositions20-source-ledger.md": '# Compositions20 — received-source ledger\n\n'+''.join(f"- `{x['id']}` — {x['sources']}\n" for x in items),
  "compositions20-legacy.json": json.dumps(items,ensure_ascii=False,indent=2)+'\n',
}
if sys.argv[1:] == ["--check"]:
  drift = [name for name, text in outputs.items() if not (ROOT / name).is_file() or (ROOT / name).read_text(encoding="utf-8") != text]
  if drift:
    print("FAIL generated output drift: " + ", ".join(drift), file=sys.stderr)
    raise SystemExit(1)
  print("PASS checked compositions20 candidate/key/ledger/legacy=20")
elif sys.argv[1:]:
  raise SystemExit("usage: compositions20-render.py [--check]")
else:
  for name, text in outputs.items():
    (ROOT / name).write_text(text, encoding="utf-8")
  print('PASS rendered compositions20 candidate/key/ledger/legacy=20')

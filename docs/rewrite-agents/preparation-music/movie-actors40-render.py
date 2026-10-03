import argparse, hashlib, json
from pathlib import Path

BASE = Path(__file__).parent
INPUTS = [BASE / 'movie-actors40-pilot.json', BASE / 'movie-actors40-expansion-20.json', BASE / 'movie-actors40-expansion-30.json', BASE / 'movie-actors40-expansion-40.json']
OUT = {
    'pack': BASE / 'movie-actors40-legacy-pack.json',
    'candidate': BASE / 'movie-actors40-blind-candidate.json',
    'key': BASE / 'movie-actors40-editorial-key.json',
    'ledger': BASE / 'movie-actors40-source-ledger.json',
}

def encode(obj):
    return (json.dumps(obj, ensure_ascii=False, indent=2) + '\n').encode('utf-8')

def build():
    records = []
    for path in INPUTS:
        records.extend(json.loads(path.read_text(encoding='utf-8'))['records'])
    records.sort(key=lambda r: r['id'])
    questions = [{'id': r['id'], 'type': 'choice', 'text': f"В художественном фильме «{r['film']}» ({r['year']}) кто сыграл {r['role']}?", 'options': r['options'], 'correct_answer': r['correct_answer'], 'explanation': r['explanation']} for r in records]
    return {
        'pack': {'id':'prep-film-actors-2','title':'Кино — актёры и роли: большой экран','description':'Сорок вопросов о знаковых ролях в полнометражном кино.','category':'Кино/Актёры','questions':questions},
        'candidate': {'id':'prep-film-actors-2-candidate','questions':[{'id':q['id'],'text':q['text'],'type':q['type'],'options':q['options']} for q in questions]},
        'key': {'id':'prep-film-actors-2-editorial-key','answers':[{'id':r['id'],'answer':r['answer'],'correct_answer':r['correct_answer'],'rationale':r['rationale']} for r in records]},
        'ledger': {'id':'prep-film-actors-2-source-ledger','accessed':'2026-10-03','records':[{'id':r['id'],'film':r['film'],'year':r['year'],'role':r['role'],'answer':r['answer'],'source':r['source'],'accessed':r.get('accessed', '2026-10-03')} for r in records]},
    }

def check(outputs):
    errors=[]
    for name,path in OUT.items():
        expected=encode(outputs[name])
        if not path.exists() or path.read_bytes()!=expected: errors.append(name)
    pack=outputs['pack']; qs=pack['questions']; positions=[q['correct_answer'] for q in qs]
    if len(qs)!=40 or len({q['id'] for q in qs})!=40 or [positions.count(i) for i in range(4)]!=[10]*4: errors.append('structure')
    if any(len(q['options'])!=4 or not (0<=q['correct_answer']<4) or not q['explanation'].strip() or not (20<=len(q['explanation'].split())<=45) for q in qs): errors.append('question')
    if any(positions[i]==positions[i+1]==positions[i+2] for i in range(38)): errors.append('runs')
    return errors

if __name__ == '__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--check',action='store_true'); args=parser.parse_args(); outputs=build()
    if args.check:
        errors=check(outputs); print(json.dumps({'status':'PASS' if not errors else 'FAIL','errors':errors,'pack_sha256':hashlib.sha256(encode(outputs['pack'])).hexdigest()},ensure_ascii=False)); raise SystemExit(bool(errors))
    for name,path in OUT.items(): path.write_bytes(encode(outputs[name]))
    print(json.dumps({'status':'WROTE','pack_sha256':hashlib.sha256(encode(outputs['pack'])).hexdigest()},ensure_ascii=False))

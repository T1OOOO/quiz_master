"""Inert Screen Song data proposal; no live writes, builds or quizctl execution."""
import argparse
import copy
import hashlib
import json
import re
import subprocess
import unicodedata
from pathlib import Path
from urllib.parse import urlsplit
ROOT = Path('C:/ap/quiz_master')
WORK = Path(__file__).resolve().parent
SCRATCH = ROOT / '.run/screen_song_integration_worker_20261014'
PILOT = ROOT / 'docs/rewrite-agents/tasks/SCREEN_SONG_PILOT_20261014'
QUIZ_ID = 'screen-song-20261014'
RAW_PATH = 'quizzes/Cinema/screen_song_20261014.json'
RUNTIME_URI = '/app/' + RAW_PATH
CONTENT_PATH = 'next/content/' + QUIZ_ID
READER_PATH = 'study/question_articles/drafts/' + QUIZ_ID + '.json'
SOURCE_TASK = 'task-4e2da7de87f048fbb77c6810a9acfe89'
INPUT_HASHES = {
    'candidate.json':'dd843139167a1a32316925983a35d53b4b77bf53463e69096f7754f221e74bc4',
    'editorial.json':'b930b1e6d091b28ff1740944612d3a3e62517a64a9dc609612c20db5549d5b3b',
    'independent-review-v2.json':'2ebed6f16385ed6bc650dc59fabd73d356856cce10b0d5be63e50b79af50128c',
}
BASELINE_HASHES = {
    'metadata/tags.v1.json':'98f019902b5cce5161b5980f3338d9cd072b094b0a760fc93adb748832546f8c',
    'next/apps/quiz_app/assets/catalog.json':'77c496394c4089a8895eb180b61592807e4c37ea15b81cb54eecc0be303be377',
    'next/apps/quiz_app/assets/study/question-articles.json':'af443be9c529dc61c30a3edd9b51327e084dccfd2a69dc88d44aac152b1b4633',
}

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def canonical_sha(value):
    return hashlib.sha256(json.dumps(value,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()).hexdigest()

def json_bytes(value):
    return (json.dumps(value,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()

def rehash(value):
    value['revision'] = {'number':1,'sha256':canonical_sha({k:v for k,v in value.items() if k!='revision'})}

def article_parts(edit):
    article = edit['article_ru']
    if '\\n' in article:
        raise ValueError('literal newline escape in article')
    marker = '\n\nИсточники:\n'
    if article.count(marker)!=1 or not article.startswith('### '):
        raise ValueError('article heading or source footer differs')
    prose,footer = article.split(marker)
    if footer.strip() != '\n'.join('- '+source['url'] for source in edit['sources']):
        raise ValueError('article source footer differs from source records')
    lines = prose.splitlines()
    # Move the first heading to title; retain secondary heading words as plain text.
    body = '\n'.join(line[4:] if line.startswith('### ') else line for line in lines[1:]).strip()
    return lines[0][4:],body

def make_proposal(candidate, editorial, taxonomy):
    items = candidate['items']
    ids = [row['id'] for row in items]
    if ids != [f'screen-song-pilot-{i:03d}' for i in range(1,5)] or [row['question_id'] for row in editorial['items']] != ids:
        raise ValueError('four unique ordered candidate/editorial IDs required')
    tags = {row['id']:row for row in taxonomy['tags']}
    taxonomy_ref = {key:taxonomy[key] for key in ('taxonomy_id','taxonomy_sha256')}
    raw = {'id':QUIZ_ID,'title':'Песни на экране: за кадром','description':'Четыре вопроса о переходе от речи к песне, аранжировке, непрерывной съёмке и создании песни для фильма.','category':'Кино','taxonomy_ref':taxonomy_ref,'questions':[]}
    draft = {'contract':'quiz-contract/v1','state':'draft','quiz_id':QUIZ_ID,'locale':'ru','taxonomy_ref':copy.deepcopy(taxonomy_ref),'questions':[]}
    manifest = {'mapping_version':'legacy-choice/v1','source_path':RAW_PATH,'source_quiz_id':QUIZ_ID,'canonical_quiz_id':QUIZ_ID,'source_category':raw['category'],'source_title':raw['title'],'source_description':raw['description'],'questions':[]}
    articles = []
    indices = []
    for item,edit in zip(items,editorial['items'],strict=True):
        options = item['options']
        if len(options)!=4 or [o['id'] for o in options]!=list('abcd'):
            raise ValueError('four ordered a/b/c/d options required')
        texts = [o['text_ru'] for o in options]
        normalized = [' '.join(unicodedata.normalize('NFC',text).casefold().split()) for text in texts]
        if any(not text for text in normalized) or len(set(normalized))!=4:
            raise ValueError('four distinct options required')
        if edit['correct_option_id'] not in [o['id'] for o in options]:
            raise ValueError('correct option absent')
        key = next(i for i,o in enumerate(options) if o['id']==edit['correct_option_id'])
        indices.append(key)
        if len(edit['tags'])!=len(set(edit['tags'])) or any(tag not in tags or tags[tag].get('player_safe') is not True for tag in edit['tags']):
            raise ValueError('all accepted tags must be registered and player-safe')
        level = edit['difficulty']
        if type(level) is not int or not 1<=level<=10:
            raise ValueError('estimated difficulty must be integer1..10')
        sources = edit['sources']
        if len(sources)!=2 or len({source['url'] for source in sources})!=2 or any(urlsplit(source['url']).scheme!='https' or not source['title'].strip() for source in sources):
            raise ValueError('two distinct HTTPS sources with exact titles required')
        title,body = article_parts(edit)
        qid = item['id']
        raw['questions'].append({'id':qid,'type':'choice','text':item['stem_ru'],'options':texts,'correct_answer':key,'difficulty':level,'editorial_tag_ids':copy.deepcopy(edit['tags']),'explanation':edit['explanation_ru']})
        canonical_options = [{'option_id':f'{qid}-opt-{i+1}','text':text} for i,text in enumerate(texts)]
        question = {'question_id':qid,'stem':item['stem_ru'],'options':canonical_options,'difficulty':'easy' if level<=3 else 'medium' if level<=6 else 'hard' if level<=8 else 'nightmare','difficulty_level':level,'editorial_tag_ids':copy.deepcopy(edit['tags']),'source':{'uri':RUNTIME_URI},'answer_kind':'single_choice','grading':{'correct_option_id':canonical_options[key]['option_id']}}
        rehash(question)
        draft['questions'].append(question)
        manifest['questions'].append({'source_id':qid,'canonical_id':qid,'source_explanation':edit['explanation_ru'],'options':[{'source_index':i,'canonical_id':option['option_id']} for i,option in enumerate(canonical_options)]})
        articles.append({'id':'question:'+qid,'title_ru':title,'body_ru':body,'status':'draft','tag_ids':copy.deepcopy(edit['tags']),'target_refs':[],'question_refs':[{'quiz_id':QUIZ_ID,'question_id':qid,'revision_sha256':question['revision']['sha256']}],'source_links':[{'url':source['url'],'title':source['title'],'supports':source['supported_claim'],'accessed':source['accessed_on']} for source in sources]})
    if indices != [0,1,2,3]:
        raise ValueError('accepted keys must remain balanced0/1/2/3')
    rehash(draft)
    manifest['source_sha256'] = hashlib.sha256(json_bytes(raw)).hexdigest()
    public = [{**{key:copy.deepcopy(value) for key,value in q.items() if key not in ('grading','editorial_tag_ids')},'quiz_id':QUIZ_ID} for q in draft['questions']]
    projection = {'contract':draft['contract'],'bundle_version':'2026.10.14.screen-song-v1','published_at':'2026-10-14T00:00:00Z','taxonomy_ref':copy.deepcopy(taxonomy_ref),'quiz':{'quiz_id':QUIZ_ID,'revision':copy.deepcopy(draft['revision']),'locale':'ru','questions':public},'private_grading':{q['question_id']:copy.deepcopy(q['grading']) for q in draft['questions']},'private_question_metadata':{q['question_id']:{'editorial_tag_ids':copy.deepcopy(q['editorial_tag_ids'])} for q in draft['questions']}}
    projection['bundle_sha256'] = canonical_sha(projection)
    return {'raw':raw,'draft':draft,'manifest':manifest,'reader':{'schema_version':'qm-question-articles/v1','articles':articles},'bundle_projection':projection}

def safe_output(path):
    resolved = Path(path).resolve()
    if not (resolved.is_relative_to(WORK) or resolved.is_relative_to(SCRATCH)):
        raise ValueError('output must stay in this task owned folders')
    return resolved

def accepted_review(record):
    if record.get('actual_hub_state')=='ACCEPTED' and record.get('actual_cli_exit')==0:
        for callback in record.get('actual_reviews',{}).values():
            call,response = callback.get('call',{}),callback.get('actual_response',{})
            args = call.get('arguments',{})
            if call.get('action')=='review' and args.get('task_id')==SOURCE_TASK and args.get('verdict')=='accept' and response.get('id')==SOURCE_TASK and response.get('state')=='ACCEPTED' and response.get('reviewer') and response.get('assignee') and response['reviewer']!=response['assignee'] and all(digest in response.get('review_note','') for name,digest in INPUT_HASHES.items() if name!='independent-review-v2.json'):
                return callback
    raise ValueError('actual accepted v2 independent callback binding input hashes required')

def load_inputs():
    for name,digest in INPUT_HASHES.items():
        if sha(PILOT/name)!=digest:
            raise ValueError('accepted input hash differs: '+name)
    for relative,digest in BASELINE_HASHES.items():
        if sha(ROOT/relative)!=digest:
            raise ValueError('baseline or taxonomy hash differs: '+relative)
    accepted_review(read(PILOT/'independent-review-v2.json'))
    return read(PILOT/'candidate.json'),read(PILOT/'editorial.json'),read(ROOT/'metadata/tags.v1.json')

def prospective_live_paths():
    return [ROOT/RAW_PATH,ROOT/CONTENT_PATH,ROOT/READER_PATH,ROOT/f'study/question_articles/reviews/{QUIZ_ID}-review.json']

def baseline():
    catalog = read(ROOT/'next/apps/quiz_app/assets/catalog.json')
    reader = read(ROOT/'next/apps/quiz_app/assets/study/question-articles.json')['articles']
    if len(catalog)!=134 or sum(row['questions_count'] for row in catalog)!=4060 or len(reader)!=260:
        raise ValueError('current baseline must remain134/4060/260')
    listing = subprocess.check_output(['rg','--files','quizzes','--glob','*.json'],cwd=ROOT,text=True).splitlines()
    raw_hashes = {Path(relative).as_posix():sha(ROOT/relative) for relative in sorted(listing)}
    if len(raw_hashes)!=134 or sum(len(read(ROOT/path)['questions']) for path in raw_hashes)!=4060:
        raise ValueError('raw baseline inventory differs')
    return {'packs':134,'questions':4060,'reader_articles':260,'raw_file_sha256':raw_hashes,'catalog_object_sha256':{row['quiz_id']:canonical_sha(row) for row in catalog},'reader_object_sha256':{row['id']:canonical_sha(row) for row in reader},'asset_file_sha256':{relative:sha(ROOT/relative) for relative in BASELINE_HASHES}}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-root',type=Path,help='new owned directory; omission is a read-only preview')
    args = parser.parse_args()
    output = safe_output(args.output_root) if args.output_root else None
    inputs = load_inputs()
    for path in prospective_live_paths():
        if path.exists():
            raise ValueError('prospective live output already exists: '+str(path))
    before = baseline()
    values = make_proposal(*inputs)
    if output is None:
        print(json.dumps({'status':'INERT_PREVIEW_ONLY','quiz_id':QUIZ_ID,'keys':[q['correct_answer'] for q in values['raw']['questions']],'planned_counts':{'packs':135,'questions':4064,'reader_articles':264}}))
        return
    if output.exists():
        raise ValueError('owned output must be absent; no clobbering')
    output.mkdir(parents=True)
    artifacts = {RAW_PATH:values['raw'],CONTENT_PATH+'/draft.json':values['draft'],CONTENT_PATH+'/manifest.json':values['manifest'],CONTENT_PATH+'/bundle-projection.json':values['bundle_projection'],READER_PATH:values['reader']}
    for relative,value in artifacts.items():
        target = output/relative
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(json_bytes(value))
    if baseline()!=before:
        raise ValueError('live baseline changed during proposal; retain evidence and stop')
    evidence = {'status':'INERT_PROPOSAL_PENDING_INDEPENDENT_INTEGRATION_REVIEW','accepted_input_sha256':INPUT_HASHES,'live_baseline_unchanged':before,'planned_counts_not_published':{'packs':135,'questions':4064,'reader_articles':264},'output_file_sha256':{relative:sha(output/relative) for relative in artifacts},'question_revision_projections_not_quizctl_validated':{q['question_id']:q['revision']['sha256'] for q in values['draft']['questions']},'canonical_draft_article_sha256':{article['id']:canonical_sha(article) for article in values['reader']['articles']},'registered_tags_retained':{row['question_id']:row['tags'] for row in inputs[1]['items']},'quizctl_import_validate_build_diff_executed':False,'runtime_writes':0,'scope':'Data projection only. Root must establish authoritative draft/bundle/manifest revisions through actual quizctl commands and independent review before live integration.'}
    (output/'proposal-evidence.json').write_bytes(json_bytes(evidence))
    print(json.dumps({'status':evidence['status'],'output':str(output),'output_file_sha256':evidence['output_file_sha256']},ensure_ascii=False))

if __name__ == '__main__':
    main()

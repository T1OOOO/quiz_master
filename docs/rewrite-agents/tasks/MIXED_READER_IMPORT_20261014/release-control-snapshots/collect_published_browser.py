from pathlib import Path
import json,hashlib,struct
r=Path('C:/ap/quiz_master');d=r/'docs/rewrite-agents/tasks/MIXED_READER_IMPORT_20261014'; b=d/'published-browser/mixed'
def read(p):return json.loads(p.read_bytes())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
summary=read(b/'pub54v2-summary.json'); commands=read(b/'pub54v2-commands.json')
assert len(summary['answered_question_ids'])==len(set(summary['answered_question_ids']))==20
assert summary['expected_score']==20 and summary['visible_result_score_confirmed']
assert all(c['actual_exit']==0 for c in commands)
assert 'Счёт: 20' in (b/'pub54v2-result-after-article1.txt').read_text(encoding='utf8')
articles=read(r/'study/question_articles/drafts/pub-connections-six-20261014.json')['articles']; checks=[]
for article in articles:
    qid=article['question_refs'][0]['question_id']; shot=b/('pub54v2-article-'+qid+'-footer.png')
    image=shot.read_bytes(); assert image.startswith(b'\x89PNG\r\n\x1a\n') and struct.unpack('>II',image[16:24])==(390,844)
    if qid.endswith('001'):
        observed=(b/'pub54v2-article1-snapshot.txt').read_text(encoding='utf8')
    else:
        observed=next((r/c['artifact']).read_text(encoding='utf8') for c in commands if c['command']==['snapshot'] and article['title_ru'] in (r/c['artifact']).read_text(encoding='utf8'))
    assert article['title_ru'] in observed and all(s['title'] in observed for s in article['source_links'])
    checks.append({'question_id':qid,'title_seen':True,'source_links_seen':len(article['source_links']),'footer_screenshot':shot.relative_to(r).as_posix(),'screenshot_sha256':sha(shot),'opened_from':'result review' if qid.endswith('001') else 'paused answer reveal'})
proof={'schema_version':'qm-reader-published-browser/v1','status':'VERIFIED','origin':'https://quiz.kotopedia.org','frozen_source':'17be4ce706cc27956c09d362cc5dc5803dd53570','helm_revision':54,'viewport':[390,844],'actual_visible_score':20,'mixed_questions':20,'articles':checks,'browser_session':'reader-17be-production-54','actual_browser_close_exit':0,'browser_close_observed':'Browser closed','actual_native_ui_runner_exit':0,'public_https_proof_sha256':sha(d/'published-https-verification.json'),'scope':'Actual compiled Flutter production UI: six Reader dialogs/footer source links/closing,20 correct answers and result preserved after final article. Root visually inspected six footer screenshots.','limitations':['Chrome mobile viewport, not a physical Android device or whole-bank fact audit.','Typed MCP browser startup was cancelled after no response; own official CLI session was recovered after daemon version mismatch and closed. No foreign browser touched.','Initial automation snapshot preceded network reveal; bounded genuine-control wait fixed the runner. Question001 article verified from the finished result review; no application code fix claimed.','Source links were visible, not clicked during this public UI run; earlier independent editorial source reading is separate.']}
(d/'published-browser/browser-proof.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print(json.dumps({'status':'VERIFIED','mobile_reader_dialogs':6,'visible_score':20,'browser_closed':True}))

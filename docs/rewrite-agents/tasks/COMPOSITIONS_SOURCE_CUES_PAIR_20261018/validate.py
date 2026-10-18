"""Validate private composition article bindings and coverage; never publish or change runtime inputs."""
from pathlib import Path
import hashlib,json,re,sys
from urllib.parse import urlsplit

ROOT=Path(__file__).resolve().parents[4]
PACKET=Path(__file__).resolve().parent
read=lambda p:json.loads(p.read_text(encoding="utf-8-sig"))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,value):
    (PACKET/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
def public_key(q):return q["quiz_id"],q["question_id"],q["revision"]["sha256"]
def ref_key(q):return q["quiz_id"],q["question_id"],q["revision_sha256"]

scope=read(PACKET/"scope.json")
for name,digest in {**scope["frozen_pins"],**scope["previous_packets"],scope["prior_coverage_path"]:scope["prior_coverage_sha256"]}.items():
    assert sha(ROOT/name)==digest,name
assert sha(PACKET/"public-pack.json")==scope["public_snapshot_sha256"]
public=read(PACKET/"public-pack.json")["quiz"]["questions"]
candidates=[q for q in public if q["question_id"] in scope["question_ids"]]
assert len(public)==20 and len(candidates)==2
assert {public_key(q) for q in candidates}<={public_key(q) for q in public}
assert not any("grading" in q for q in public)
assert sha(PACKET/'proposed-questions.json')==scope['proposed_questions_sha256']
assert sha(PACKET/'wording-proposals.json')==scope['wording_proposals_sha256']
proposed=read(PACKET/'proposed-questions.json')['questions'];changes=read(PACKET/'wording-proposals.json')['changes']
assert len(proposed)==len(changes)==2
by_public={q['question_id']:q for q in candidates}
for q in proposed:
    original=by_public[q['origin_ref']['question_id']]
    assert ref_key(q['origin_ref'])==public_key(original)
    assert q['options']==original['options'] and q['answer_kind']==original['answer_kind']
    assert q['proposed_revision_assigned'] is False and 'revision' not in q
    change=next(i for i in changes if i['origin_ref']==q['origin_ref'])
    assert change['published_stem']==original['stem'] and change['proposed_stem']==q['stem']
    assert q['stem']!=original['stem']
    cue={'compositions003':'Beethoven-Haus','compositions016':'Holst, Gustav'}[q['origin_ref']['question_id']]
    assert cue in original['stem'] and cue not in q['stem']

articles=read(PACKET/"articles.json")
assert articles["schema_version"]=="qm-question-articles/v1" and len(articles["articles"])==2
by_id={q["question_id"]:q for q in candidates}
assert {a["id"] for a in articles["articles"]}=={"question:"+i for i in by_id}
word_counts={}
for a in articles["articles"]:
    q=by_id[a["id"][9:]]
    assert a["status"]=="draft" and a["target_refs"]==[] and a["tag_ids"]==["domain:arts"]
    assert len(a["question_refs"])==1 and ref_key(a["question_refs"][0])==public_key(q)
    assert "\\n" not in a["body_ru"] and a["title_ru"].strip()
    word_counts[a["id"]]=len(re.findall(r"\S+",a["body_ru"]))
    assert 160<=word_counts[a["id"]]<=260,(a["id"],word_counts[a["id"]])
    assert 1<=len(a["source_links"])<=5
    assert len({link["url"] for link in a["source_links"]})==len(a["source_links"])
    for link in a["source_links"]:
        url=urlsplit(link["url"])
        assert url.scheme=="https" and url.netloc and not url.username and not url.password
        assert link["accessed"]=="2026-10-18" and all(link[k].strip() for k in ["title","supports"])
coverage=read(ROOT/scope["prior_coverage_path"])
assert {ref_key(q) for q in coverage["questions"]}=={public_key(q) for q in public}
for item in coverage["questions"]:
    if item["question_id"] in by_id:
        assert item["status"]=="missing"
        item.update(status="private_draft",article_id="question:"+item["question_id"],source_path=(PACKET/"articles.json").relative_to(ROOT).as_posix(),source_sha256=sha(PACKET/"articles.json"))
coverage["counts"]={state:sum(q["status"]==state for q in coverage["questions"]) for state in ["runtime_asset","private_draft","missing"]}
assert coverage["counts"]==dict(runtime_asset=0,private_draft=2,missing=18)
write("coverage.json",coverage)
result=dict(status="pass_structural_only",article_sha256=sha(PACKET/"articles.json"),sources_sha256=sha(PACKET/"SOURCES_EN.md"),articles=2,word_counts=word_counts,coverage=coverage["counts"],exact_public_refs=True,proposed_current_distinction_verified=True,blind_scope="unhinted_proposed_editorial_candidates_not_hinted_public_stems",published_source_cues=2,proposed_explicit_source_cues=0,future_revision_assigned=False,article_rebinding_required_after_revision=True,frozen_inputs_and_previous_packets_preserved=True,external_review="pending",publication_attempted=False)
if "--final" in sys.argv:
    review=read(PACKET/"review.json")
    assert review['reviewed_proposals']['sha256']==sha(PACKET/'wording-proposals.json')
    assert review['reviewed_proposed_questions']['sha256']==sha(PACKET/'proposed-questions.json')
    assert review['reviewed_public_snapshot']['sha256']==sha(PACKET/'public-pack.json')
    assert review['ordering']['clean_public_blind_solve'] is False
    assert review['ordering']['new_independent_proposed_solve'] is True
    assert all(i['question_repair_verdict']=='accepted_as_private_proposal_only' and i['question_revision_sha256']==by_id[i['id'][9:]]['revision']['sha256'] for i in review['items'])

    assert review["reviewed_file"]["sha256"]==sha(PACKET/"articles.json")
    assert {i["id"] for i in review["items"]}=={a["id"] for a in articles["articles"]}
    assert all(i["verdict"]=="accepted_for_draft" for i in review["items"])
    integrity=read(PACKET/"key-integrity.json")
    assert integrity["blind_answer_sha256"]==sha(PACKET/"blind-answers.json")
    assert len(integrity["questions"])==2 and all(i["blind_answer_matches_local_key"] and i["original_stem_and_options_match"] and i["proposed_options_unchanged"] for i in integrity["questions"])
    result.update(native_review_sha256=sha(PACKET/"review.json"),native_review="accepted_for_draft",different_provider_acceptance=False,independent_answers_match_local_keys=2,key_integrity_sha256=sha(PACKET/"key-integrity.json"))
write("validation-final.json" if "--final" in sys.argv else "validation-structural.json",result)
print(json.dumps(result,ensure_ascii=False))

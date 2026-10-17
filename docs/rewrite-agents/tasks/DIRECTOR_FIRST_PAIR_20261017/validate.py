"""Validate private director article bindings and coverage; never publish or change runtime inputs."""
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
for item in read(PACKET/"coverage-inventory.json")["files"]:
    assert sha(ROOT/item["path"])==item["sha256"]
assert read(PACKET/"coverage-inventory.json")["matching_question_refs_before_work"]==[]
public=read(PACKET/"public-pack.json")["quiz"]["questions"]
candidates=read(PACKET/"candidate-questions.json")["questions"]
assert len(public)==40 and len(candidates)==2
assert {public_key(q) for q in candidates}<={public_key(q) for q in public}
assert not any("grading" in q for q in public)
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
        assert link["accessed"]=="2026-10-17" and all(link[k].strip() for k in ["title","supports"])
coverage=read(ROOT/scope["prior_coverage_path"])
assert {ref_key(q) for q in coverage["questions"]}=={public_key(q) for q in public}
for item in coverage["questions"]:
    if item["question_id"] in by_id:
        assert item["status"]=="missing"
        item.update(status="private_draft",article_id="question:"+item["question_id"],source_path=(PACKET/"articles.json").relative_to(ROOT).as_posix(),source_sha256=sha(PACKET/"articles.json"))
coverage["counts"]={state:sum(q["status"]==state for q in coverage["questions"]) for state in ["runtime_asset","private_draft","missing"]}
assert coverage["counts"]==dict(runtime_asset=0,private_draft=2,missing=38)
write("coverage.json",coverage)
result=dict(status="pass_structural_only",article_sha256=sha(PACKET/"articles.json"),sources_sha256=sha(PACKET/"SOURCES_EN.md"),articles=2,word_counts=word_counts,coverage=coverage["counts"],exact_public_refs=True,frozen_inputs_and_previous_packets_preserved=True,external_review="pending",publication_attempted=False)
if "--final" in sys.argv:
    review=read(PACKET/"review.json")
    assert review["reviewed_file"]["sha256"]==sha(PACKET/"articles.json")
    assert {i["id"] for i in review["items"]}=={a["id"] for a in articles["articles"]}
    assert all(i["verdict"]=="accepted_for_draft" for i in review["items"])
    integrity=read(PACKET/"key-integrity.json")
    assert integrity["blind_answer_sha256"]==sha(PACKET/"blind-answers.json")
    assert len(integrity["questions"])==2 and all(i["blind_answer_matches_local_key"] and i["stem_and_options_match"] for i in integrity["questions"])
    result.update(native_review_sha256=sha(PACKET/"review.json"),native_review="accepted_for_draft",different_provider_acceptance=False,independent_answers_match_local_keys=2,key_integrity_sha256=sha(PACKET/"key-integrity.json"))
write("validation-final.json" if "--final" in sys.argv else "validation-structural.json",result)
print(json.dumps(result,ensure_ascii=False))

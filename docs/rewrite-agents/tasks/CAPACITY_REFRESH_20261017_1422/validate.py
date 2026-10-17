from pathlib import Path
import json,hashlib
r=Path("E:/Projects/quiz_master");p=r/"docs/rewrite-agents/tasks/CAPACITY_REFRESH_20261017_1422"
read=lambda f:json.loads(f.read_text(encoding="utf-8-sig"))
h=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
a=read(p/"analysis.json");scope=read(p/"scope.json")
assert h(p/"analysis.json")=="1099ee064927665c7021c76d158d57c7f9ba45467a507935c17dd51ef7dcd7d0"
for f,k in [("inventory-observation.json","inventory_sha256"),("production-observation.json","production_sha256")]:
 assert h(p/f)==a[k]
 envelope=read(p/f);assert envelope["actual_exit"]==0 and envelope["mutation"] is False
obs=json.loads(read(p/"inventory-observation.json")["stdout"])
prod=json.loads(read(p/"production-observation.json")["stdout"])
for pathkey,hashkey in [("historical_proposal_path","historical_proposal_sha256"),("prior_project_aggregate_path","prior_project_aggregate_sha256"),("previous_health_path","previous_health_sha256")]:assert h(r/a[pathkey])==a[hashkey]
old=read(r/a["historical_proposal_path"]);byname={x["name"]:x["allocated_bytes"] for x in obs["release_directories"]}
assert len(old["candidate_directories"])==len(a["matching_candidate_directories"])==28
assert {Path(x["path"]).name:x["observed_allocated_bytes"] for x in old["candidate_directories"]}=={x["name"]:x["allocated_bytes"] for x in a["matching_candidate_directories"]}
assert all(byname[x["name"]]==x["allocated_bytes"] for x in a["matching_candidate_directories"])
pool=sum(x["allocated_bytes"] for x in a["matching_candidate_directories"])
floor=obs["disk_total_bytes"]//5+1-obs["disk_available_bytes"]
assert a["disk_floor_deficit_bytes"]==floor and a["historical_pool_allocated_bytes"]==pool
assert a["planning_reserve_bytes"]==1024**3+64*1024**2
assert a["planning_target_bytes"]==floor+a["planning_reserve_bytes"]
assert a["pool_shortfall_to_floor_bytes"]==floor-pool>0
assert a["pool_shortfall_to_planning_target_bytes"]==a["planning_target_bytes"]-pool
assert a["previous_health_free_bytes"]-prod["disk_available"]==a["health_decrease_bytes"]
assert prod["feedback_open"]==prod["feedback_count"]==43 and not prod["strict20_pass"]
assert not a["mutation"]
for f,digest in scope["frozen_pins"].items():assert h(r/f)==digest
review=read(p/"review.json");assert review["overall_verdict"]=="accepted_for_observation_only"
assert review["reviewed_file"]["sha256"]==h(p/"analysis.json")
result=dict(status="pass_read_only_capacity_observation_only",analysis_sha256=h(p/"analysis.json"),review_sha256=h(p/"review.json"),floor_deficit_bytes=floor,historical_pool_shortfall_to_floor_bytes=floor-pool,feedback_open=43,publication_attempted=False,remote_mutation=False,different_provider_acceptance=False)
(p/"validation.json").write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps(result))

#!/usr/bin/env python3
"""Deterministic, dependency-free executable checks for live-team-contract/v1."""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASE_SUMMARY = ROOT.parents[1] / "quiz-contract" / "v1" / "summary.json"
BASE_CONTENT_HASH = "5cc3275eb90dc71d58a5dc5d42be0fece52b727ead2bdf6ad9e7727a30df5f4e"
ID = re.compile(r"^[a-z][a-z0-9-]{2,63}$")
HASH = re.compile(r"^[0-9a-f]{64}$")
QR = re.compile(r"^[0-9a-f]{32}$")
MANUAL = re.compile(r"^[0-9ABCDEFGHJKMNPQRSTVWXYZ]{8}$")
RESUME = re.compile(r"^[0-9a-f]{64}$")
FORBIDDEN = {"qr_token", "manual_code", "resume_token", "share_token", "host_token", "answer_key", "grading", "correct", "correct_option_id", "correct_option_ids", "accepted_variants", "is_correct"}
HOST_COMMANDS = {"admission.lock", "round.close", "round.reveal", "round.next", "captain.transfer"}
PUBLIC_RESULT_FIELDS = {"final_standings", "revealed_questions", "explanations"}


class ContractError(ValueError):
    def __init__(self, error_id):
        self.error_id = error_id
        super().__init__(error_id)


def fail(error_id): raise ContractError(error_id)
def require(ok, error_id):
    if not ok: fail(error_id)
def load(path):
    try: return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError): fail(f"json.{path.name}.invalid")
def digest(value): return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
def shape(value, required, allowed, error_id):
    require(isinstance(value, dict), f"{error_id}.not_object")
    require(required <= set(value), f"{error_id}.missing_field")
    require(set(value) <= allowed, f"{error_id}.unknown_field")
def stable(value, error_id): require(isinstance(value, str) and ID.fullmatch(value), error_id)
def utc(value, error_id): require(isinstance(value, str) and value.endswith("Z"), error_id)
def rev(value, error_id):
    shape(value, {"number", "sha256"}, {"number", "sha256"}, error_id)
    require(isinstance(value["number"], int) and not isinstance(value["number"], bool) and value["number"] > 0, f"{error_id}.number")
    require(isinstance(value["sha256"], str) and HASH.fullmatch(value["sha256"]), f"{error_id}.sha256")
def no_secret(value, context):
    if isinstance(value, dict):
        for key, child in value.items():
            require(key not in FORBIDDEN, f"{context}.secret.{key}")
            no_secret(child, context)
    elif isinstance(value, list):
        for child in value: no_secret(child, context)


def schema_declarations(schemas):
    expected = {"live-team.schema.json": "live-team-contract/v1/live-team", "live-events.schema.json": "live-team-contract/v1/live-events", "live-policy.schema.json": "live-team-contract/v1/live-policy"}
    require(set(schemas) == set(expected), "schema.set.invalid")
    for name, identifier in expected.items():
        schema = schemas[name]
        require(schema.get("$schema") == "https://json-schema.org/draft/2020-12/schema" and schema.get("$id") == identifier, f"schema.{name}.identity")
        require(schema.get("type") == "object" or "oneOf" in schema, f"schema.{name}.root")
        require(schema.get("$defs", {}) == {} or isinstance(schema.get("$defs"), dict), f"schema.{name}.definitions")
        for definition in schema.get("$defs", {}).values():
            if definition.get("type") == "object": require(definition.get("additionalProperties") is False, f"schema.{name}.definition.open")


def validate_schema(instance, schema, root, name):
    if "$ref" in schema:
        ref = schema["$ref"]
        require(ref.startswith("#/$defs/"), f"{name}.external_reference")
        return validate_schema(instance, root["$defs"][ref.rsplit("/", 1)[1]], root, name)
    if "const" in schema: require(instance == schema["const"], f"{name}.const_mismatch")
    if "enum" in schema: require(instance in schema["enum"], f"{name}.enum_mismatch")
    types = {"object": lambda x: isinstance(x, dict), "array": lambda x: isinstance(x, list), "string": lambda x: isinstance(x, str), "integer": lambda x: isinstance(x, int) and not isinstance(x, bool), "boolean": lambda x: isinstance(x, bool)}
    if schema.get("type"): require(types[schema["type"]](instance), f"{name}.type_mismatch")
    if isinstance(instance, dict):
        missing = set(schema.get("required", [])) - set(instance)
        require(not missing, f"{name}.{sorted(missing)[0]}.required_property_missing" if missing else f"{name}.required_property_missing")
        props = schema.get("properties", {})
        extra = set(instance) - set(props)
        if schema.get("additionalProperties") is False: require(not extra, f"{name}.{sorted(extra)[0]}.unknown_property" if extra else f"{name}.unknown_property")
        for key, value in instance.items():
            if key in props: validate_schema(value, props[key], root, f"{name}.{key}")
            elif isinstance(schema.get("additionalProperties"), dict): validate_schema(value, schema["additionalProperties"], root, f"{name}.{key}")
    if isinstance(instance, list):
        require(len(instance) >= schema.get("minItems", 0), f"{name}.too_few_items")
        if "maxItems" in schema: require(len(instance) <= schema["maxItems"], f"{name}.too_many_items")
        if "items" in schema:
            for i, item in enumerate(instance): validate_schema(item, schema["items"], root, f"{name}[{i}]")
    if isinstance(instance, str):
        require(len(instance) >= schema.get("minLength", 0), f"{name}.short_string")
        if "pattern" in schema: require(re.fullmatch(schema["pattern"], instance) is not None, f"{name}.pattern_mismatch")
    if isinstance(instance, int) and not isinstance(instance, bool) and "minimum" in schema: require(instance >= schema["minimum"], f"{name}.minimum")
    if "oneOf" in schema:
        matches = 0
        for candidate in schema["oneOf"]:
            try: validate_schema(instance, candidate, root, name)
            except ContractError: pass
            else: matches += 1
        require(matches == 1, f"{name}.one_of_mismatch")
    if "allOf" in schema:
        for candidate in schema["allOf"]: validate_schema(instance, candidate, root, name)


def validate_session(x):
    fields = {"session_id","host_id","bundle_version","bundle_sha256","scoring_policy_version","settings","state"}; shape(x, fields, fields, "session")
    stable(x["session_id"], "session.id"); stable(x["host_id"], "session.host_id")
    require(isinstance(x["bundle_sha256"], str) and HASH.fullmatch(x["bundle_sha256"]) and x["scoring_policy_version"] == "scoring/v1", "session.base_pin")
    settings = {"team_capacity","round_seconds","auto_close_when_all_answer"}; shape(x["settings"], settings, settings, "settings")
    require(x["settings"]["team_capacity"] == 50 and isinstance(x["settings"]["round_seconds"], int) and x["settings"]["round_seconds"] > 0 and x["settings"]["auto_close_when_all_answer"] is False, "settings.policy")
    state = {"phase","room_version","event_sequence","admission"}; shape(x["state"], state, state, "state")
    require(x["state"]["phase"] == "active" and x["state"]["admission"] == "locked" and x["state"]["room_version"] >= 1 and x["state"]["event_sequence"] >= 0, "session.state")


def validate_invite(x, session):
    fields = {"invite_id","session_id","qr_token","manual_code","expires_at","revoked","rotated"}; shape(x, fields, fields, "invitation")
    stable(x["invite_id"], "invitation.id"); require(x["session_id"] == session["session_id"], "invitation.session")
    require(isinstance(x["qr_token"], str) and QR.fullmatch(x["qr_token"]) and isinstance(x["manual_code"], str) and MANUAL.fullmatch(x["manual_code"]), "invitation.form")
    utc(x["expires_at"], "invitation.expiry"); require(x["revoked"] is False and x["rotated"] is False, "invitation.positive_state")


def validate_join(x, session):
    fields = {"session_id","team_id","captain_id","resume_token","resume_expires_at","generic_failure"}; shape(x, fields, fields, "join")
    require(x["session_id"] == session["session_id"] and x["generic_failure"] == "invalid_join" and isinstance(x["resume_token"], str) and RESUME.fullmatch(x["resume_token"]), "join.exchange")
    for key in ("team_id", "captain_id"): stable(x[key], f"join.{key}")
    utc(x["resume_expires_at"], "join.resume_expiry")


def validate_round(x, session):
    fields = {"round_id","session_id","state","bundle_version","bundle_sha256","question_id","question_revision","option_order","server_opened_at","server_deadline_at"}; shape(x, fields, fields, "round")
    require(x["session_id"] == session["session_id"] and x["state"] == "open" and x["bundle_version"] == session["bundle_version"] and x["bundle_sha256"] == session["bundle_sha256"], "round.pin_state")
    stable(x["round_id"], "round.id"); stable(x["question_id"], "round.question_id"); rev(x["question_revision"], "round.question_revision")
    require(isinstance(x["option_order"], list) and len(x["option_order"]) == len(set(x["option_order"])) and x["option_order"], "round.option_order")
    utc(x["server_opened_at"], "round.opened_at"); utc(x["server_deadline_at"], "round.deadline_at"); require(x["server_opened_at"] < x["server_deadline_at"], "round.deadline_order")


def validate_answer(x, session, round_):
    fields = {"session_id","round_id","team_id","captain_id","bundle_sha256","question_id","question_revision","answer","idempotency_key","payload_digest","receipt"}; shape(x, fields, fields, "answer")
    require(x["session_id"] == session["session_id"] and x["round_id"] == round_["round_id"] and x["bundle_sha256"] == round_["bundle_sha256"] and x["question_id"] == round_["question_id"] and x["question_revision"] == round_["question_revision"], "answer.pin")
    stable(x["team_id"], "answer.team"); stable(x["captain_id"], "answer.captain"); require(isinstance(x["payload_digest"], str) and HASH.fullmatch(x["payload_digest"]), "answer.payload_digest")
    expected = digest({key: x[key] for key in ("session_id", "round_id", "team_id", "captain_id", "question_id", "question_revision", "answer")})
    require(x["payload_digest"] == expected, "answer.payload_digest_binding")
    require(isinstance(x["answer"], dict) and set(x["answer"]) in ({"option_id"},{"option_ids"},{"text"}), "answer.typed")
    r = x["receipt"]; receipt_fields = {"receipt_id","session_id","round_id","team_id","captain_id","question_id","question_revision","payload_digest","accepted_at"}; shape(r, receipt_fields, receipt_fields, "receipt")
    require(all(r[k] == x[k] for k in ("session_id","round_id","team_id","captain_id","question_id","question_revision","payload_digest")), "receipt.binding")
    stable(r["receipt_id"], "receipt.id"); utc(r["accepted_at"], "receipt.accepted_at")


def validate_event(event, session, round_):
    fields = {"session_id","round_id","sequence","room_version","server_at","audience","kind","data","outbox_id"}; shape(event, fields, fields, "event")
    require(event["session_id"] == session["session_id"] and event["round_id"] == round_["round_id"] and event["sequence"] > 0 and event["room_version"] > 0, "event.envelope")
    stable(event["outbox_id"], "event.outbox"); utc(event["server_at"], "event.server_at")
    a, k, d = event["audience"], event["kind"], event["data"]
    require(isinstance(d, dict), "event.data")
    if a == "presenter":
        require(k == "round.opened" and set(d) == {"question_id","question_revision","option_order","deadline_at","answered_team_count"}, "event.presenter.shape"); no_secret(d, "event.presenter")
    elif a == "team":
        require(k == "team.receipt" and set(d) == {"target_team_id","receipt_id","accepted_at"}, "event.team.shape"); no_secret(d, "event.team")
    elif a == "host":
        require(k == "team.answer_arrived" and set(d) == {"team_id","receipt_id","answer","accepted_at"}, "event.host.shape"); no_secret(d, "event.host")
    elif a == "reveal":
        require(k == "question.revealed" and set(d) == {"question_id","question_revision","correct_answer","explanation"}, "event.reveal.shape")
        require(isinstance(d["correct_answer"], dict) and isinstance(d["explanation"], str) and d["explanation"], "event.reveal.content"); no_secret(d["correct_answer"], "event.reveal.display_answer")
    else: fail("event.audience.unsupported")


def validate_reconnect(x, session):
    fields = {"session_id","audience","last_seen_sequence","mode"}; shape(x, fields, fields, "reconnect")
    require(x["session_id"] == session["session_id"] and x["audience"] in {"host","presenter","team","public"} and isinstance(x["last_seen_sequence"], int) and x["last_seen_sequence"] >= 0 and x["mode"] in {"contiguous_events","audience_snapshot"}, "reconnect.invalid")


def validate_access(x, session):
    required = {"session_id","audience","scope","credential_kind"}; shape(x, required, required | {"share_token","share_expires_at","share_revoked"}, "access")
    scopes = {"host":"full_session","team":"own_answers_and_standings","public":"final_standings_and_reveals"}
    require(x["session_id"] == session["session_id"] and scopes.get(x["audience"]) == x["scope"], "access.scope")
    if x["audience"] == "public":
        require(x["credential_kind"] == "public_share" and set(x) == required | {"share_token","share_expires_at","share_revoked"} and isinstance(x["share_token"], str) and QR.fullmatch(x["share_token"]), "access.public_credential")
        utc(x["share_expires_at"], "access.share_expiry"); require(x["share_revoked"] is False, "access.positive_share")
    else: require(x["credential_kind"] == "authenticated" and set(x) == required, "access.private_credential")


def validate_positive(p, schemas):
    policy_schema = schemas["live-policy.schema.json"]; validate_schema(p["policy"], policy_schema, policy_schema, "schema.policy")
    require(set(p["policy"]["invitation"]["expiry_triggers"]) == {"time","admission_lock","session_start","session_finish","revoked","rotated"}, "policy.invitation.expiry_triggers")
    require(set(p["policy"]["public_result"]["fields"]) == PUBLIC_RESULT_FIELDS, "policy.public_result.fields")
    missing_rotation = copy.deepcopy(p["policy"]); missing_rotation["invitation"]["expiry_triggers"].remove("rotated")
    reject_any(lambda: require(set(missing_rotation["invitation"]["expiry_triggers"]) == {"time","admission_lock","session_start","session_finish","revoked","rotated"}, "policy.invitation.expiry_triggers"), "probe.policy_missing_rotation")
    duplicate_public = copy.deepcopy(p["policy"]); duplicate_public["public_result"]["fields"] = ["final_standings","final_standings"]
    reject_any(lambda: require(set(duplicate_public["public_result"]["fields"]) == PUBLIC_RESULT_FIELDS, "policy.public_result.fields"), "probe.policy_incomplete_public_result")
    team_schema, event_schema = schemas["live-team.schema.json"], schemas["live-events.schema.json"]
    validate_schema(p["session"], team_schema, team_schema, "schema.session")
    for field, definition in (("invitation", "invitation"), ("join_exchange", "joinExchange"), ("round", "round"), ("answer_write", "answerWrite"), ("reconnect", "reconnect")):
        validate_schema(p[field], team_schema["$defs"][definition], team_schema, f"schema.{field}")
    for item in p["result_access"]: validate_schema(item, team_schema["$defs"]["resultAccess"], team_schema, "schema.result_access")
    for item in p["events"]: validate_schema(item, event_schema, event_schema, "schema.event")
    validate_session(p["session"]); validate_invite(p["invitation"], p["session"]); validate_join(p["join_exchange"], p["session"]); validate_round(p["round"], p["session"]); validate_answer(p["answer_write"], p["session"], p["round"])
    require(len(p["events"]) == 4, "positive.events.incomplete")
    for event in p["events"]: validate_event(event, p["session"], p["round"])
    require([event["sequence"] for event in p["events"]] == [5,6,6,7], "positive.events.sequence")
    require({event["outbox_id"] for event in p["events"]} == {"outbox-005","outbox-006","outbox-006-team-red","outbox-007"}, "positive.events.outbox")
    validate_reconnect(p["reconnect"], p["session"])
    for access in p["result_access"]: validate_access(access, p["session"])
    leaked_presenter = copy.deepcopy(p["events"][0]); leaked_presenter["data"]["qr_token"] = "0123456789abcdef0123456789abcdef"
    reject_any(lambda: validate_schema(leaked_presenter, event_schema, event_schema, "schema.presenter_leak"), "probe.presenter_secret")
    wrong_pair = copy.deepcopy(p["events"][0]); wrong_pair["kind"] = "team.answer_arrived"
    reject_any(lambda: validate_schema(wrong_pair, event_schema, event_schema, "schema.wrong_audience_kind"), "probe.wrong_audience_kind")
    bad_access = {"session_id":p["session"]["session_id"],"audience":"team","scope":"full_session","credential_kind":"public_share","share_token":"0123456789abcdef0123456789abcdef","share_expires_at":"2026-09-27T10:00:00Z","share_revoked":False}
    reject_any(lambda: validate_schema(bad_access, team_schema["$defs"]["resultAccess"], team_schema, "schema.public_share_full_session"), "probe.public_share_full_session")
    nested_presenter = copy.deepcopy(p["events"][0]); nested_presenter["data"]["question_revision"]["correct_answer"] = {"text":"leak"}
    reject_any(lambda: validate_schema(nested_presenter, event_schema, event_schema, "schema.nested_presenter"), "probe.nested_presenter")
    nested_host = copy.deepcopy(p["events"][1]); nested_host["data"]["answer"]["grading"] = {"correct_option_id":"opt-sun"}
    reject_any(lambda: validate_schema(nested_host, event_schema, event_schema, "schema.nested_host"), "probe.nested_host")
    nested_reveal = copy.deepcopy(p["events"][3]); nested_reveal["data"]["correct_answer"]["accepted_variants"] = ["The Sun"]
    reject_any(lambda: validate_schema(nested_reveal, event_schema, event_schema, "schema.nested_reveal"), "probe.nested_reveal_schema")
    reject_any(lambda: validate_event(nested_reveal, p["session"], p["round"]), "probe.nested_reveal_semantic")


def reject_any(call, probe):
    try: call()
    except ContractError: return
    fail(f"{probe}.unexpected_accept")


def input_shape(x, fields, operation):
    expected = set(fields) | {"operation"}; shape(x, expected, expected, "fixture.input")
    require(x["operation"] == operation, "fixture.operation.mismatch")
    return tuple(x[field] for field in fields)


def validate_manual_code_input(x):
    (code,) = input_shape(x, ("manual_code",), "validate_manual_code")
    require(isinstance(code, str), "manual_code.type")
    require(len(code) >= 8, "manual_code.short_length")
    require(len(code) <= 8, "manual_code.long_length")
    require(all(ch in "0123456789ABCDEFGHJKMNPQRSTVWXYZ" for ch in code), "manual_code.ambiguous_character")
    require(MANUAL.fullmatch(code), "manual_code.form")


def validate_admission_input(x):
    qr_token, manual_code, expires_at, revoked, rotated, session_phase, admission, team_count, server_at = input_shape(x, ("qr_token","manual_code","expires_at","revoked","rotated","session_phase","admission","team_count","server_at"), "admission")
    require(isinstance(qr_token, str) and QR.fullmatch(qr_token), "admission.qr_form")
    require(isinstance(manual_code, str) and MANUAL.fullmatch(manual_code), "admission.manual_form")
    utc(expires_at, "admission.expires_at"); utc(server_at, "admission.server_at")
    require(isinstance(revoked, bool), "admission.revoked.type"); require(isinstance(rotated, bool), "admission.rotated.type")
    require(session_phase in {"lobby","active","finished","cancelled"}, "admission.phase.type")
    require(admission in {"open","locked"}, "admission.state.type")
    require(isinstance(team_count, int) and not isinstance(team_count, bool) and team_count >= 0, "admission.team_count.type")
    require(server_at <= expires_at, "admission.invite_expired")
    require(not revoked, "admission.invite_revoked")
    require(not rotated, "admission.invite_rotated")
    require(admission == "open", "admission.locked")
    require(session_phase == "lobby", "admission.session_started")
    require(team_count < 50, "admission.capacity_reached")


def validate_authorize_host_input(x):
    credential_kind, actor_id, host_id, command = input_shape(x, ("credential_kind","actor_id","host_id","command"), "authorize_host")
    require(isinstance(credential_kind, str) and isinstance(command, str), "host_auth.input_type")
    stable(actor_id, "host_auth.actor_id"); stable(host_id, "host_auth.host_id")
    require(command in HOST_COMMANDS, "host_auth.command_unknown")
    require(credential_kind != "invite", "host_auth.invite_not_host")
    require(credential_kind == "host_session" and actor_id == host_id, "host_auth.unauthorized")


def validate_authorize_team_input(x):
    team_name, actor_id, team_id, captain_id = input_shape(x, ("team_name","actor_id","team_id","captain_id"), "authorize_team")
    require(isinstance(team_name, str) and team_name, "team_auth.team_name")
    stable(actor_id, "team_auth.actor_id"); stable(team_id, "team_auth.team_id"); stable(captain_id, "team_auth.captain_id")
    require(actor_id == captain_id, "team_auth.team_name_not_identity")


def validate_claim_captain_input(x):
    existing, requested = input_shape(x, ("existing_captain_id","requested_captain_id"), "claim_captain")
    stable(existing, "captain.existing_id"); stable(requested, "captain.requested_id")
    require(existing == requested, "captain.already_claimed")


def validate_transfer_input(x):
    actor, host, current, replacement = input_shape(x, ("actor_id","host_id","current_captain_id","new_captain_id"), "captain_transfer")
    for value, error_id in ((actor,"transfer.actor_id"),(host,"transfer.host_id"),(current,"transfer.current_id"),(replacement,"transfer.new_id")): stable(value, error_id)
    require(current != replacement, "transfer.same_captain")
    require(actor == host, "transfer.actor_not_host")


def validate_answer_command(x, positive):
    round_id, question_revision, bundle_sha256, server_received_at, client_at, idempotency_key, payload_digest, prior_answer, serialized_first = input_shape(x, ("round_id","question_revision","bundle_sha256","server_received_at","client_at","idempotency_key","payload_digest","prior_answer","serialized_first"), "submit_answer")
    stable(round_id, "answer_command.round_id"); rev(question_revision, "answer_command.question_revision")
    require(isinstance(bundle_sha256, str) and HASH.fullmatch(bundle_sha256), "answer_command.bundle")
    utc(server_received_at, "answer_command.server_received_at")
    require(client_at is None or (isinstance(client_at, str) and client_at.endswith("Z")), "answer_command.client_at")
    require(isinstance(idempotency_key, str) and idempotency_key, "answer_command.idempotency_key")
    require(isinstance(payload_digest, str) and HASH.fullmatch(payload_digest), "answer_command.payload_digest")
    require(serialized_first in {"answer","close"}, "answer_command.serialization")
    if prior_answer is not None:
        shape(prior_answer, {"idempotency_key","payload_digest"}, {"idempotency_key","payload_digest"}, "answer_command.prior")
        require(isinstance(prior_answer["idempotency_key"], str) and prior_answer["idempotency_key"], "answer_command.prior.key")
        require(isinstance(prior_answer["payload_digest"], str) and HASH.fullmatch(prior_answer["payload_digest"]), "answer_command.prior.digest")
    round_ = positive["round"]
    require(round_id == round_["round_id"], "answer.stale_round")
    require(question_revision == round_["question_revision"], "answer.stale_question_revision")
    require(bundle_sha256 == round_["bundle_sha256"], "answer.stale_bundle")
    if prior_answer is not None:
        if idempotency_key == prior_answer["idempotency_key"]:
            require(payload_digest == prior_answer["payload_digest"], "answer.idempotency_conflict")
            return
        fail("answer.final_submission_exists")
    require(client_at is None, "answer.client_clock_not_authoritative")
    require(server_received_at <= round_["server_deadline_at"], "answer.server_deadline_elapsed")
    require(serialized_first == "answer", "answer.close_won_race")


def validate_result_request(x, schemas, positive):
    access, requester_team_id, target_team_id, server_at, requested_fields = input_shape(x, ("access","requester_team_id","target_team_id","server_at","requested_fields"), "result_request")
    require(isinstance(access, dict), "result_request.access_type")
    require(requester_team_id is None or (isinstance(requester_team_id, str) and ID.fullmatch(requester_team_id)), "result_request.requester_team")
    require(target_team_id is None or (isinstance(target_team_id, str) and ID.fullmatch(target_team_id)), "result_request.target_team")
    utc(server_at, "result_request.server_at")
    require(isinstance(requested_fields, list) and requested_fields and all(isinstance(v, str) and v for v in requested_fields) and len(requested_fields) == len(set(requested_fields)), "result_request.fields")
    team_schema = schemas["live-team.schema.json"]
    validate_schema(access, team_schema["$defs"]["resultAccess"], team_schema, "schema.result_request.access")
    require(access["session_id"] == positive["session"]["session_id"], "result_request.session")
    if access["audience"] == "team":
        require(requester_team_id is not None and target_team_id is not None and requester_team_id == target_team_id, "result_access.cross_team")
        require(set(requested_fields) <= {"own_answers","standings"}, "result_access.team_overexposure")
    elif access["audience"] == "public":
        require(requester_team_id is None and target_team_id is None, "result_access.public_identity")
        require(server_at <= access["share_expires_at"], "result_access.public_expired")
        require(not access["share_revoked"], "result_access.public_revoked")
        require(set(requested_fields) <= PUBLIC_RESULT_FIELDS, "result_access.public_overexposure")
    else:
        require(requester_team_id is None and target_team_id is None, "result_access.host_identity")


def validate_replay_input(x, schemas, positive):
    request, event_sequence, event_room_version, current_room_version, available_from_sequence, target_team_id, authorized_team_id = input_shape(x, ("request","event_sequence","event_room_version","current_room_version","available_from_sequence","target_team_id","authorized_team_id"), "replay_event")
    require(isinstance(request, dict), "replay.request_type")
    team_schema = schemas["live-team.schema.json"]
    validate_schema(request, team_schema["$defs"]["reconnect"], team_schema, "schema.replay.request")
    for value, error_id in ((event_sequence,"replay.event_sequence_type"),(event_room_version,"replay.event_room_version_type"),(current_room_version,"replay.current_room_version_type"),(available_from_sequence,"replay.available_from_type")):
        require(isinstance(value, int) and not isinstance(value, bool) and value >= 0, error_id)
    stable(target_team_id, "replay.target_team"); stable(authorized_team_id, "replay.authorized_team")
    require(request["session_id"] == positive["session"]["session_id"], "replay.session")
    require(target_team_id == authorized_team_id, "replay.cross_team")
    require(event_sequence > request["last_seen_sequence"], "replay.duplicate_or_stale_event")
    if request["mode"] == "contiguous_events": require(request["last_seen_sequence"] + 1 >= available_from_sequence and event_sequence == request["last_seen_sequence"] + 1, "replay.gap_requires_snapshot")
    require(event_room_version >= current_room_version, "replay.stale_room_version")


def mutate_target(x, schemas, positive):
    target, path, mutation, validator = input_shape(x, ("target","path","mutation","validator"), "schema_mutation")
    require(isinstance(target, str) and isinstance(validator, str), "mutation.selector_type")
    require(isinstance(path, list) and path and all(isinstance(part, str) and part for part in path), "mutation.path")
    require(isinstance(mutation, dict), "mutation.not_object")
    require(mutation.get("kind") in {"set", "remove"}, "mutation.kind")
    expected_mutation_fields = {"kind", "value"} if mutation["kind"] == "set" else {"kind"}
    shape(mutation, expected_mutation_fields, expected_mutation_fields, "mutation")
    targets = {"presenter_event": positive["events"][0], "host_event": positive["events"][1], "team_event": positive["events"][2], "reveal_event": positive["events"][3]}
    require(target in targets, "mutation.target_unknown")
    require(validator == "event_schema", "mutation.validator_unknown")
    record = copy.deepcopy(targets[target]); cursor = record
    for part in path[:-1]:
        require(isinstance(cursor, dict) and part in cursor, "mutation.path_missing"); cursor = cursor[part]
    require(isinstance(cursor, dict), "mutation.path_parent")
    if mutation["kind"] == "set": cursor[path[-1]] = mutation["value"]
    else:
        require(path[-1] in cursor, "mutation.path_missing")
        del cursor[path[-1]]
    event_schema = schemas["live-events.schema.json"]
    definition = {"presenter_event":"presenter","host_event":"host","team_event":"team","reveal_event":"reveal"}[target]
    validate_schema(record, event_schema["$defs"][definition], event_schema, f"schema.{target}")
    validate_event(record, positive["session"], positive["round"])


def execute_operation_input(x, schemas, positive):
    require(isinstance(x, dict), "fixture.input.not_object")
    operation = x.get("operation")
    dispatch = {
        "validate_manual_code": lambda: validate_manual_code_input(x), "admission": lambda: validate_admission_input(x),
        "authorize_host": lambda: validate_authorize_host_input(x), "authorize_team": lambda: validate_authorize_team_input(x),
        "claim_captain": lambda: validate_claim_captain_input(x), "captain_transfer": lambda: validate_transfer_input(x),
        "submit_answer": lambda: validate_answer_command(x, positive), "result_request": lambda: validate_result_request(x, schemas, positive),
        "replay_event": lambda: validate_replay_input(x, schemas, positive), "schema_mutation": lambda: mutate_target(x, schemas, positive),
    }
    require(operation in dispatch, "fixture.operation.unknown"); dispatch[operation]()


def reject_case(case, schemas, positive):
    shape(case, {"name","input","expected_error"}, {"name","input","expected_error"}, "fixture.case")
    require(isinstance(case["name"], str) and case["name"], "fixture.name")
    require(isinstance(case["expected_error"], str) and case["expected_error"], "fixture.expected_error")
    try: execute_operation_input(case["input"], schemas, positive)
    except ContractError as exc:
        require(exc.error_id == case["expected_error"], f"fixture.{case['name']}.wrong_error.{exc.error_id}")
        return case["name"]
    fail(f"fixture.{case['name']}.unexpected_accept")


def poison_probe(cases, schemas, positive):
    exact, observed = [], {}
    for case in cases:
        poisoned = copy.deepcopy(case)
        poisoned["input"] = {key: (value if key == "operation" else "IRRELEVANT") for key, value in poisoned["input"].items()}
        try: execute_operation_input(poisoned["input"], schemas, positive)
        except ContractError as exc:
            observed[case["name"]] = exc.error_id
            if exc.error_id == case["expected_error"]: exact.append(case["name"])
        else: observed[case["name"]] = "ACCEPTED"
    require(set(exact) != {case["name"] for case in cases}, "fixture.poisoning.same_success_set")
    require(len(exact) < len(cases), "fixture.poisoning.materiality")
    return {"exact_expected_errors": sorted(exact), "observed_hash": digest(observed)}


def validate_operation_positives(schemas, positive):
    invitation, session, round_, answer = positive["invitation"], positive["session"], positive["round"], positive["answer_write"]
    operation_inputs = [
        {"operation":"validate_manual_code","manual_code":invitation["manual_code"]},
        {"operation":"admission","qr_token":invitation["qr_token"],"manual_code":invitation["manual_code"],"expires_at":invitation["expires_at"],"revoked":False,"rotated":False,"session_phase":"lobby","admission":"open","team_count":2,"server_at":"2026-09-20T10:00:00Z"},
        {"operation":"authorize_host","credential_kind":"host_session","actor_id":session["host_id"],"host_id":session["host_id"],"command":"round.close"},
        {"operation":"authorize_team","team_name":"Red Team","actor_id":answer["captain_id"],"team_id":answer["team_id"],"captain_id":answer["captain_id"]},
        {"operation":"claim_captain","existing_captain_id":answer["captain_id"],"requested_captain_id":answer["captain_id"]},
        {"operation":"captain_transfer","actor_id":session["host_id"],"host_id":session["host_id"],"current_captain_id":answer["captain_id"],"new_captain_id":"captain-blue"},
        {"operation":"submit_answer","round_id":round_["round_id"],"question_revision":round_["question_revision"],"bundle_sha256":round_["bundle_sha256"],"server_received_at":answer["receipt"]["accepted_at"],"client_at":None,"idempotency_key":answer["idempotency_key"],"payload_digest":answer["payload_digest"],"prior_answer":None,"serialized_first":"answer"},
        {"operation":"result_request","access":positive["result_access"][1],"requester_team_id":answer["team_id"],"target_team_id":answer["team_id"],"server_at":"2026-09-20T12:00:00Z","requested_fields":["own_answers","standings"]},
        {"operation":"replay_event","request":{"session_id":session["session_id"],"audience":"team","last_seen_sequence":4,"mode":"contiguous_events"},"event_sequence":5,"event_room_version":3,"current_room_version":3,"available_from_sequence":5,"target_team_id":answer["team_id"],"authorized_team_id":answer["team_id"]},
    ]
    for operation_input in operation_inputs: execute_operation_input(operation_input, schemas, positive)
    return operation_inputs


def input_closure_probe(cases, schemas, positive):
    representatives = {}
    for case in cases: representatives.setdefault(case["input"]["operation"], case["input"])
    for operation, example in representatives.items():
        removable = next(key for key in example if key != "operation")
        missing = copy.deepcopy(example); del missing[removable]
        try: execute_operation_input(missing, schemas, positive)
        except ContractError as exc: require(exc.error_id == "fixture.input.missing_field", f"closure.{operation}.missing_wrong_error")
        else: fail(f"closure.{operation}.missing_accepted")
        unknown = copy.deepcopy(example); unknown["unexpected"] = "IRRELEVANT"
        try: execute_operation_input(unknown, schemas, positive)
        except ContractError as exc: require(exc.error_id == "fixture.input.unknown_field", f"closure.{operation}.unknown_wrong_error")
        else: fail(f"closure.{operation}.unknown_accepted")
    return sorted(representatives)


def main():
    parser = argparse.ArgumentParser(); parser.add_argument("--write-summary", action="store_true"); args = parser.parse_args()
    base = load(BASE_SUMMARY); require(base == {**base, "contract":"quiz-contract/v1", "content_hash":BASE_CONTENT_HASH}, "base_contract.hash")
    schemas = {p.name: load(p) for p in sorted((ROOT / "schemas").glob("*.json"))}; schema_declarations(schemas)
    positive = load(ROOT / "fixtures" / "positive.json")
    negative_document = load(ROOT / "fixtures" / "negative.json"); shape(negative_document, {"cases"}, {"cases"}, "negative_document")
    negatives = negative_document["cases"]; require(isinstance(negatives, list), "negative_document.cases")
    validate_positive(positive, schemas)
    operation_positives = validate_operation_positives(schemas, positive)
    rejected_names = [reject_case(case, schemas, positive) for case in negatives]
    require(len(rejected_names) == len(set(rejected_names)) == 33, "negative.coverage")
    closed_operations = input_closure_probe(negatives, schemas, positive)
    poison = poison_probe(negatives, schemas, positive)
    result = {"contract":"live-team-contract/v1","base_contract":"quiz-contract/v1","base_content_hash":BASE_CONTENT_HASH,"positive_cases":9 + len(operation_positives),"closed_input_operations":closed_operations,"negative_rejected":sorted(rejected_names),"negative_errors":{case["name"]:case["expected_error"] for case in sorted(negatives, key=lambda item: item["name"])},"poison_probe":poison,"schema_files":sorted(schemas),"content_hash":digest({"base":base,"schemas":schemas,"positive":positive,"negative":negatives})}
    output = json.dumps(result, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    if args.write_summary: (ROOT / "summary.json").write_text(output + "\n", encoding="utf-8")
    print(output)


if __name__ == "__main__":
    try: main()
    except ContractError as exc:
        print(f"CONTRACT_ERROR: {exc.error_id}", file=sys.stderr); sys.exit(1)

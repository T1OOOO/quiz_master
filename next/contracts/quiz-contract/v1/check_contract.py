#!/usr/bin/env python3
"""Deterministic, dependency-free executable checks for proposed quiz-contract/v1."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCHEMAS = ROOT / "schemas"
FIXTURES = ROOT / "fixtures"
ID_RE = re.compile(r"^[a-z][a-z0-9-]{2,63}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
SECRET_KEYS = {
    "grading", "private_grading", "correct_option_id", "correct_option_ids",
    "accepted_variants", "correct_text", "correct_answer", "answer_key", "correct",
    "is_correct", "solution",
}
TEAM_KEYS = {
    "team_id", "team_name", "captain_id", "join_code", "standing",
    "team_score", "immediate_correctness", "team", "teams", "captain", "standings",
}
SCHEMA_IDS = {
    "draft-quiz.schema.json": "quiz-contract/v1/draft-quiz",
    "published-bundle.schema.json": "quiz-contract/v1/published-bundle",
    "public-question.schema.json": "quiz-contract/v1/public-question",
    "reveal.schema.json": "quiz-contract/v1/reveal",
    "attempts.schema.json": "quiz-contract/v1/attempts",
    "room-event.schema.json": "quiz-contract/v1/room-event",
    "error-envelope.schema.json": "quiz-contract/v1/error-envelope",
}


class ContractError(ValueError):
    pass


def load(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ContractError(f"{path.name}: invalid JSON: {exc}") from exc


def digest(value) -> str:
    encoded = json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def payload_digest(write) -> str:
    return digest({key: write[key] for key in ("attempt_id", "participant_id", "question_id", "question_revision", "answer")})


def copy_json(value):
    return json.loads(json.dumps(value))


def locate(value, path):
    for part in path:
        value = value[int(part)] if isinstance(value, list) else value[part]
    return value


def mutate(value, path, replacement=None, delete=False):
    parent = locate(value, path[:-1])
    key = int(path[-1]) if isinstance(parent, list) else path[-1]
    if delete:
        del parent[key]
    else:
        parent[key] = replacement


def normalized_text(value: str) -> str:
    if not isinstance(value, str):
        raise ContractError("text submission must be a string")
    return " ".join(unicodedata.normalize("NFC", value).casefold().split())


def require(condition: bool, message: str):
    if not condition:
        raise ContractError(message)


def require_shape(value, required, allowed, name):
    require(isinstance(value, dict), f"{name} must be an object")
    require(set(value).issuperset(required), f"{name} missing required fields")
    extra = set(value).difference(allowed)
    require(not extra, f"{name} has unknown fields {sorted(extra)}")


def require_id(value, name: str):
    require(isinstance(value, str) and ID_RE.fullmatch(value) is not None, f"{name} must be a stable lowercase ID")


def require_revision(value, name: str):
    require_shape(value, {"number", "sha256"}, {"number", "sha256"}, name)
    require(isinstance(value.get("number"), int) and value["number"] >= 1, f"{name}.number must be a positive integer")
    require(isinstance(value.get("sha256"), str) and SHA256_RE.fullmatch(value["sha256"]) is not None, f"{name}.sha256 must be 64 lowercase hex characters")


def reject_secret(value, context: str, allowed=frozenset()):
    if isinstance(value, dict):
        for key, child in value.items():
            require(key not in SECRET_KEYS or key in allowed, f"{context} leaks secret field {key}")
            reject_secret(child, context, allowed)
    elif isinstance(value, list):
        for child in value:
            reject_secret(child, context, allowed)


def reject_team(value, context: str):
    if isinstance(value, dict):
        for key, child in value.items():
            require(key not in TEAM_KEYS, f"{context} includes team-reserved field {key}")
            reject_team(child, context)
    elif isinstance(value, list):
        for child in value:
            reject_team(child, context)


def validate_question(question, quiz_id: str, public=False):
    allowed = {"question_id", "revision", "stem", "options", "difficulty", "source", "media", "answer_kind", "grading"}
    if public:
        allowed.add("quiz_id")
    require_shape(question, {"question_id", "revision", "stem", "options", "difficulty", "source", "answer_kind"}, allowed, "question")
    require_id(question.get("question_id"), "question_id")
    require_revision(question.get("revision"), "question revision")
    require(isinstance(question.get("stem"), str) and question["stem"].strip(), "stem is required")
    options = question.get("options")
    require(isinstance(options, list) and 4 <= len(options) <= 6, "choice questions require 4-6 options")
    option_ids = []
    for option in options:
        require_shape(option, {"option_id", "text"}, {"option_id", "text", "media"}, "option")
        require_id(option.get("option_id"), "option_id")
        require(isinstance(option.get("text"), str) and option["text"].strip(), "option text is required")
        option_ids.append(option["option_id"])
    require(len(option_ids) == len(set(option_ids)), "option IDs must be unique within a question")
    require(question.get("difficulty") in {"unknown", "easy", "medium", "hard"}, "difficulty must be explicit; unknown never becomes zero")
    source = question.get("source")
    require_shape(source, {"uri"}, {"uri", "title"}, "source")
    require(isinstance(source.get("uri"), str) and source["uri"], "source.uri is required")
    require(question.get("answer_kind") in {"single_choice", "multiple_choice", "normalized_text"}, "unknown answer_kind")
    media = question.get("media", [])
    require(isinstance(media, list), "media must be an array")
    for item in media:
        require_shape(item, {"uri"}, {"uri", "kind", "alt"}, "media item")
        require(isinstance(item.get("uri"), str) and item["uri"], "media item uri is required")
    return option_ids


def validate_grading(question, option_ids):
    grading = question.get("grading")
    require(isinstance(grading, dict), "draft question grading is required")
    kind = question["answer_kind"]
    if kind == "single_choice":
        require(set(grading) == {"correct_option_id"}, "single grading must contain only correct_option_id")
        require(grading["correct_option_id"] in option_ids, "single correct option must resolve")
    elif kind == "multiple_choice":
        ids = grading.get("correct_option_ids")
        require(set(grading) == {"correct_option_ids"} and isinstance(ids, list) and ids, "multiple grading requires a nonempty correct_option_ids")
        require(len(ids) == len(set(ids)) and set(ids).issubset(option_ids), "multiple correct options must resolve uniquely")
    else:
        variants = grading.get("accepted_variants")
        require(set(grading) == {"accepted_variants"} and isinstance(variants, list) and variants, "text grading requires explicit accepted_variants")
        normalized = [normalized_text(item) for item in variants]
        require(all(normalized) and len(normalized) == len(set(normalized)), "text variants must be nonempty and distinct after normalization")


def validate_draft(draft):
    require_shape(draft, {"contract", "state", "quiz_id", "revision", "locale", "questions"}, {"contract", "state", "quiz_id", "revision", "locale", "questions"}, "draft quiz")
    require(draft.get("contract") == "quiz-contract/v1", "wrong contract")
    require(draft.get("state") == "draft", "draft state required")
    require_id(draft.get("quiz_id"), "quiz_id")
    require_revision(draft.get("revision"), "quiz revision")
    require(isinstance(draft.get("locale"), str) and draft["locale"], "locale required")
    questions = draft.get("questions")
    require(isinstance(questions, list) and questions, "questions are required")
    ids = set()
    for question in questions:
        option_ids = validate_question(question, draft["quiz_id"])
        require(question["question_id"] not in ids, "duplicate question_id")
        ids.add(question["question_id"])
        validate_grading(question, option_ids)


def validate_public(question):
    reject_secret(question, "public question")
    require_shape(question, {"quiz_id", "question_id", "revision", "stem", "options", "difficulty", "source", "answer_kind"}, {"quiz_id", "question_id", "revision", "stem", "options", "difficulty", "source", "media", "answer_kind"}, "public question")
    require_id(question.get("quiz_id"), "public quiz_id")
    option_ids = validate_question(question, question["quiz_id"], public=True)
    require("explanation" not in question, "public question leaks explanation")
    return option_ids


def validate_reveal(reveal, public_questions=None, draft=None):
    reject_secret(reveal, "reveal payload", {"correct_answer"})
    require_shape(reveal, {"quiz_id", "question_id", "question_revision", "correct_answer", "explanation"}, {"quiz_id", "question_id", "question_revision", "correct_answer", "explanation"}, "reveal payload")
    require_id(reveal.get("quiz_id"), "reveal quiz_id")
    require_id(reveal.get("question_id"), "reveal question_id")
    require_revision(reveal.get("question_revision"), "reveal question_revision")
    require_shape(reveal.get("correct_answer"), {"text"}, {"text", "option_id"}, "reveal correct_answer")
    require(isinstance(reveal["correct_answer"]["text"], str) and reveal["correct_answer"]["text"], "reveal correct answer text is required")
    require(isinstance(reveal.get("explanation"), str) and reveal["explanation"].strip(), "reveal explanation is required")
    if public_questions is not None:
        matches = [item for item in public_questions if item["quiz_id"] == reveal["quiz_id"] and item["question_id"] == reveal["question_id"] and item["revision"] == reveal["question_revision"]]
        require(len(matches) == 1, "reveal has a stale quiz/question revision reference")
        if draft is not None:
            draft_question = next(item for item in draft["questions"] if item["question_id"] == reveal["question_id"] and item["revision"] == reveal["question_revision"])
            grading = draft_question["grading"]
            answer = reveal["correct_answer"]
            if draft_question["answer_kind"] == "single_choice":
                expected_id = grading["correct_option_id"]
                expected_option = next(option for option in matches[0]["options"] if option["option_id"] == expected_id)
                require(answer.get("option_id") == expected_id and answer["text"] == expected_option["text"], "reveal single answer must match private grading and public option")
            elif draft_question["answer_kind"] == "normalized_text":
                require("option_id" not in answer and answer["text"] in grading["accepted_variants"], "reveal text must display one permitted variant only")
            else:
                expected = grading["correct_option_ids"]
                require(answer.get("option_ids") == expected and answer["text"] == ", ".join(next(option["text"] for option in matches[0]["options"] if option["option_id"] == item) for item in expected), "reveal multiple answer must match private grading and public option text")


def validate_attempt(attempt, public_questions, bundle):
    require_shape(attempt, {"attempt_id", "participant_id", "bundle_version", "bundle_sha256", "scoring_policy_version", "question_snapshots", "status"}, {"attempt_id", "participant_id", "bundle_version", "bundle_sha256", "scoring_policy_version", "question_snapshots", "status", "history"}, "attempt")
    require(attempt.get("status") in {"started", "finished"}, "attempt status invalid")
    require_id(attempt.get("attempt_id"), "attempt_id")
    require_id(attempt.get("participant_id"), "participant_id")
    require(isinstance(attempt.get("bundle_version"), str) and attempt["bundle_version"], "bundle_version required")
    require(isinstance(attempt.get("bundle_sha256"), str) and SHA256_RE.fullmatch(attempt["bundle_sha256"]) is not None, "bundle_sha256 invalid")
    require(attempt["bundle_version"] == bundle["bundle_version"] and attempt["bundle_sha256"] == bundle["bundle_sha256"], "attempt must pin the controlled published bundle version and hash")
    require(isinstance(attempt.get("scoring_policy_version"), str) and attempt["scoring_policy_version"], "scoring_policy_version required")
    snapshots = attempt.get("question_snapshots")
    require(isinstance(snapshots, list) and snapshots, "attempt must pin question snapshots")
    public_by_id = {item["question_id"]: item for item in public_questions}
    for snapshot in snapshots:
        question_id = snapshot.get("question_id")
        require(question_id in public_by_id, "attempt snapshot has stale question reference")
        require_shape(snapshot, {"question_id", "question_revision", "option_order", "position_to_option_id"}, {"question_id", "question_revision", "option_order", "position_to_option_id"}, "attempt snapshot")
        require_revision(snapshot.get("question_revision"), "snapshot question_revision")
        require(snapshot["question_revision"] == public_by_id[question_id]["revision"], "attempt snapshot has stale question revision")
        expected = [item["option_id"] for item in public_by_id[question_id]["options"]]
        order = snapshot.get("option_order")
        mapping = snapshot.get("position_to_option_id")
        require(isinstance(order, list) and sorted(order) == sorted(expected), "attempt option_order must pin every option exactly once")
        require(isinstance(mapping, dict) and [mapping.get(str(i)) for i in range(len(order))] == order, "attempt position mapping must match option_order")


def validate_write(write, attempt, public_questions):
    require_shape(write, {"attempt_id", "participant_id", "question_id", "question_revision", "answer", "idempotency_key", "payload_digest", "receipt", "accepted_at", "same_key_same_payload", "same_key_same_payload_receipt_id", "same_key_different_payload"}, {"attempt_id", "participant_id", "question_id", "question_revision", "answer", "idempotency_key", "payload_digest", "receipt", "accepted_at", "same_key_same_payload", "same_key_same_payload_receipt_id", "same_key_different_payload"}, "answer write")
    require_id(write.get("attempt_id"), "write attempt_id")
    require(write["attempt_id"] == attempt["attempt_id"], "write attempt_id must match attempt")
    require_id(write.get("participant_id"), "write participant_id")
    require(write["participant_id"] == attempt["participant_id"], "write participant must match attempt")
    snapshots = {item["question_id"]: item for item in attempt["question_snapshots"]}
    require(write["question_id"] in snapshots, "write question must have a pinned snapshot")
    require_revision(write.get("question_revision"), "write question_revision")
    require(write["question_revision"] == snapshots[write["question_id"]]["question_revision"], "write revision must match snapshot")
    public = {item["question_id"]: item for item in public_questions}[write["question_id"]]
    require(write["question_revision"] == public["revision"], "write revision must match public question")
    answer = write["answer"]
    if public["answer_kind"] == "single_choice":
        require_shape(answer, {"option_id"}, {"option_id"}, "single-choice answer")
        require(answer["option_id"] in snapshots[write["question_id"]]["option_order"], "single-choice answer option not pinned")
    elif public["answer_kind"] == "multiple_choice":
        require_shape(answer, {"option_ids"}, {"option_ids"}, "multiple-choice answer")
        require(isinstance(answer["option_ids"], list) and len(answer["option_ids"]) == len(set(answer["option_ids"])) and set(answer["option_ids"]).issubset(snapshots[write["question_id"]]["option_order"]), "multiple-choice answer options not pinned")
    else:
        require_shape(answer, {"text"}, {"text"}, "text answer")
        require(isinstance(answer["text"], str), "text answer must be string")
    require(isinstance(write.get("idempotency_key"), str) and write["idempotency_key"], "idempotency_key required")
    require(isinstance(write.get("payload_digest"), str) and SHA256_RE.fullmatch(write["payload_digest"]) is not None, "payload_digest invalid")
    require(write["payload_digest"] == payload_digest(write), "payload_digest must equal canonical accepted answer payload")
    require_shape(write["receipt"], {"receipt_id", "attempt_id", "participant_id", "question_id", "question_revision", "accepted_at"}, {"receipt_id", "attempt_id", "participant_id", "question_id", "question_revision", "accepted_at"}, "answer receipt")
    require_id(write["receipt"]["receipt_id"], "receipt_id")
    require(all(write["receipt"][key] == write[key] for key in ("attempt_id", "participant_id", "question_id", "question_revision")), "receipt must bind accepted write identity")
    require(isinstance(write["accepted_at"], str) and write["accepted_at"].endswith("Z") and write["receipt"]["accepted_at"] == write["accepted_at"], "accepted_at must be a server UTC timestamp")
    require(write.get("same_key_same_payload") == "same_receipt", "same idempotency key and payload must replay receipt")
    require(write["same_key_same_payload_receipt_id"] == write["receipt"]["receipt_id"], "same payload must return original receipt")
    require(write.get("same_key_different_payload") == "idempotency_conflict", "different payload must conflict")


def validate_finish(finish, attempt, write=None):
    require_shape(finish, {"attempt_id", "participant_id", "status", "finished_at", "server_score", "history"}, {"attempt_id", "participant_id", "status", "finished_at", "server_score", "history"}, "attempt finish")
    require(finish.get("attempt_id") == attempt["attempt_id"] and finish.get("participant_id") == attempt["participant_id"], "finish identity must match its attempt")
    require(finish.get("status") == "finished" and isinstance(finish.get("finished_at"), str) and finish["finished_at"].endswith("Z"), "finish must be server timestamped")
    require(isinstance(finish.get("server_score"), int) and finish["server_score"] >= 0, "finish score must be server-authoritative")
    history = finish.get("history")
    snapshots = {item["question_id"]: item for item in attempt["question_snapshots"]}
    require(isinstance(history, list) and history, "finish history is required")
    for item in history:
        require_shape(item, {"question_id", "question_revision", "receipt_id"}, {"question_id", "question_revision", "receipt_id"}, "history item")
        require(item["question_id"] in snapshots, "history question must match attempt snapshot")
        require_revision(item["question_revision"], "history question_revision")
        require(item["question_revision"] == snapshots[item["question_id"]]["question_revision"], "history revision must match attempt snapshot")
        require_id(item["receipt_id"], "history receipt_id")
        if write is not None and item["question_id"] == write["question_id"]:
            require(item["receipt_id"] == write["receipt"]["receipt_id"], "history receipt must reference accepted write receipt")


def validate_room(event):
    require_shape(event, {"session_id", "round_id", "sequence", "room_version", "server_at", "audience", "kind", "data"}, {"session_id", "round_id", "sequence", "room_version", "server_at", "audience", "kind", "data"}, "base room envelope")
    require_id(event["session_id"], "session_id")
    require_id(event["round_id"], "round_id")
    require(isinstance(event["sequence"], int) and event["sequence"] >= 1, "sequence must be monotonic positive")
    require(isinstance(event["room_version"], int) and event["room_version"] >= 1, "room_version must be positive")
    require(isinstance(event["server_at"], str) and event["server_at"].endswith("Z"), "server timestamp must be UTC RFC3339")
    require(event["audience"] in {"participant", "host", "presenter", "all"}, "audience invalid")
    require(event["kind"] in {"round.opened", "round.closed", "question.revealed"}, "base room event kind invalid or reserved for P33")
    reject_secret(event, "room event")
    reject_team(event, "room event")
    if event["kind"] == "round.opened":
        require_shape(event["data"], {"question_id"}, {"question_id"}, "round.opened data")
        require_id(event["data"]["question_id"], "room question_id")
    else:
        require_shape(event["data"], set(), set(), f"{event['kind']} data")


def validate_error(error):
    reject_secret(error, "error envelope")
    require_shape(error, {"code", "message", "retryable", "details"}, {"code", "message", "retryable", "details"}, "error envelope")
    require(error["code"] in {"deadline_exceeded", "stale_revision", "stale_round", "forbidden", "validation_failed", "idempotency_conflict"}, "error code invalid")
    require(isinstance(error["message"], str) and isinstance(error["retryable"], bool) and isinstance(error["details"], dict), "error envelope value types invalid")


def validate_published(bundle, draft):
    require_shape(bundle, {"contract", "bundle_version", "bundle_sha256", "published_at", "quiz", "private_grading"}, {"contract", "bundle_version", "bundle_sha256", "published_at", "quiz", "private_grading"}, "published bundle")
    require(bundle.get("contract") == "quiz-contract/v1", "published bundle contract invalid")
    require(isinstance(bundle.get("bundle_version"), str) and bundle["bundle_version"], "published bundle_version required")
    require(isinstance(bundle.get("bundle_sha256"), str) and SHA256_RE.fullmatch(bundle["bundle_sha256"]) is not None, "published bundle hash invalid")
    quiz = bundle["quiz"]
    require_shape(quiz, {"quiz_id", "revision", "locale", "questions"}, {"quiz_id", "revision", "locale", "questions"}, "published canonical public quiz")
    expected_public = [{key: value for key, value in question.items() if key != "grading"} | {"quiz_id": draft["quiz_id"]} for question in draft["questions"]]
    canonical_quiz = {"quiz_id": draft["quiz_id"], "revision": draft["revision"], "locale": draft["locale"], "questions": expected_public}
    require(quiz == canonical_quiz, "published bundle must contain exact canonical immutable public quiz content")
    for question in quiz["questions"]: validate_public(question)
    expected_grading = {question["question_id"]: question["grading"] for question in draft["questions"]}
    require(bundle["private_grading"] == expected_grading, "published private_grading must exactly equal canonical draft grading")
    hash_input = {key: value for key, value in bundle.items() if key != "bundle_sha256"}
    require(bundle["bundle_sha256"] == digest(hash_input), "published bundle_sha256 must equal canonical hash input excluding bundle_sha256")


def validate_schema_declarations(schemas):
    require(set(schemas) == set(SCHEMA_IDS), "schema set is incomplete")
    for filename, identifier in SCHEMA_IDS.items():
        schema = schemas[filename]
        require(schema.get("$schema") == "https://json-schema.org/draft/2020-12/schema", f"{filename} schema dialect invalid")
        require(schema.get("$id") == identifier and schema.get("type") == "object", f"{filename} identity/type invalid")
        require(schema.get("additionalProperties") is False, f"{filename} must close its root shape")
        require(isinstance(schema.get("required"), list) and isinstance(schema.get("properties"), dict), f"{filename} must declare required properties")
    public = schemas["public-question.schema.json"]
    option = public.get("$defs", {}).get("option", {})
    require(option.get("additionalProperties") is False and {"option_id", "text"}.issubset(set(option.get("required", []))), "public schema option shape must be closed")
    room = schemas["room-event.schema.json"]
    require(room.get("$defs", {}).get("roundOpenedData", {}).get("additionalProperties") is False, "room schema round data must be closed")
    attempts = schemas["attempts.schema.json"]
    require(attempts.get("$defs", {}).get("answerWrite", {}).get("additionalProperties") is False, "attempt schema answer write must be closed")


def validate_schema(instance, schema, root, name):
    if "$ref" in schema:
        ref = schema["$ref"]
        require(ref.startswith("#/$defs/"), f"{name}: unsupported schema ref")
        return validate_schema(instance, root["$defs"][ref.rsplit("/", 1)[1]], root, name)
    if "const" in schema: require(instance == schema["const"], f"{name}: const mismatch")
    if "enum" in schema: require(instance in schema["enum"], f"{name}: enum mismatch")
    kind = schema.get("type")
    type_ok = {"object": lambda x: isinstance(x, dict), "array": lambda x: isinstance(x, list), "string": lambda x: isinstance(x, str), "integer": lambda x: isinstance(x, int) and not isinstance(x, bool), "boolean": lambda x: isinstance(x, bool)}
    if kind: require(kind in type_ok and type_ok[kind](instance), f"{name}: schema type {kind} mismatch")
    if isinstance(instance, dict):
        required = set(schema.get("required", [])); require(required.issubset(instance), f"{name}: schema required property missing")
        props = schema.get("properties", {})
        additional = schema.get("additionalProperties", True)
        if additional is False: require(set(instance).issubset(props), f"{name}: schema extra property")
        for key, value in instance.items():
            if key in props:
                validate_schema(value, props[key], root, f"{name}.{key}")
            elif isinstance(additional, dict):
                validate_schema(value, additional, root, f"{name}.{key}")
        if "maxProperties" in schema: require(len(instance) <= schema["maxProperties"], f"{name}: schema maxProperties")
    if isinstance(instance, list):
        require(len(instance) >= schema.get("minItems", 0), f"{name}: schema minItems")
        if "maxItems" in schema: require(len(instance) <= schema["maxItems"], f"{name}: schema maxItems")
        if "items" in schema:
            for index, value in enumerate(instance): validate_schema(value, schema["items"], root, f"{name}[{index}]")
    if isinstance(instance, str):
        require(len(instance) >= schema.get("minLength", 0), f"{name}: schema minLength")
        if "pattern" in schema: require(re.fullmatch(schema["pattern"], instance) is not None, f"{name}: schema pattern")
    if isinstance(instance, int) and not isinstance(instance, bool) and "minimum" in schema: require(instance >= schema["minimum"], f"{name}: schema minimum")
    if "not" in schema:
        try: validate_schema(instance, schema["not"], root, name)
        except ContractError: pass
        else: raise ContractError(f"{name}: schema not")
    if "anyOf" in schema:
        matches = 0
        for candidate in schema["anyOf"]:
            try: validate_schema(instance, candidate, root, name)
            except ContractError: pass
            else: matches += 1
        require(matches >= 1, f"{name}: schema anyOf")
    if "oneOf" in schema:
        matches = 0
        for candidate in schema["oneOf"]:
            try: validate_schema(instance, candidate, root, name)
            except ContractError: pass
            else: matches += 1
        require(matches == 1, f"{name}: schema oneOf")


def validate_scoring(fixtures):
    for case in fixtures:
        kind = case["kind"]
        expected = case["expected_correct"]
        if kind == "single_choice":
            actual = case["submission"] == case["key"]["correct_option_id"]
        elif kind == "multiple_choice":
            actual = set(case["submission"]) == set(case["key"]["correct_option_ids"]) and len(case["submission"]) == len(set(case["submission"]))
        elif kind == "normalized_text":
            actual = normalized_text(case["submission"]) in {normalized_text(item) for item in case["key"]["accepted_variants"]}
        else:
            raise ContractError("unknown scoring fixture kind")
        require(actual == expected, f"scoring fixture {case['id']} disagrees with policy")
        require(case["points"] == (1 if expected else 0), f"scoring fixture {case['id']} points must be 0 or 1")
        require(case.get("speed_bonus") == 0, f"scoring fixture {case['id']} must have no speed bonus")


def validate_negative(case, positive, schemas):
    name = case["name"]
    subject = case["subject"]
    try:
        if subject == "positive_mutation":
            value = copy_json(locate(positive, case["target"]))
            mutate(value, case["path"], case.get("replacement"), case.get("delete", False))
            validator = case["validator"]
            if validator == "published": validate_published(value, positive["draft"])
            elif validator == "attempt": validate_attempt(value, positive["public_questions"], positive["published_bundle"])
            elif validator == "write": validate_write(value, positive["attempt"], positive["public_questions"])
            elif validator == "finish": validate_finish(value, positive["attempt"], positive["answer_write"])
            elif validator == "reveal": validate_reveal(value, positive["public_questions"], positive["draft"])
            elif validator == "public": validate_public(value)
            elif validator == "room": validate_room(value)
            elif validator == "error": validate_error(value)
            else: raise ContractError("unknown mutation validator")
        elif subject == "schema_mutation":
            value = copy_json(locate(positive, case["target"]))
            mutate(value, case["path"], case.get("replacement"), case.get("delete", False))
            schema = schemas[case["schema"]]
            selected = schema
            for definition in case.get("defs", []):
                selected = selected["$defs"][definition]
            validate_schema(value, selected, schema, case["name"])
        elif subject == "draft": validate_draft(case["value"])
        elif subject == "public": validate_public(case["value"])
        elif subject == "reveal": validate_reveal(case["value"], case.get("public_questions"), case.get("draft"))
        elif subject == "attempt": validate_attempt(case["value"], case["public_questions"], case["bundle"])
        elif subject == "write": validate_write(case["value"], case["attempt"], case["public_questions"])
        elif subject == "finish": validate_finish(case["value"], case["attempt"])
        elif subject == "published": validate_published(case["value"], case["draft"])
        elif subject == "room": validate_room(case["value"])
        elif subject == "error": validate_error(case["value"])
        elif subject == "legacy":
            value = case["value"]
            require("correct_answer" in value, "legacy correct_answer required")
            answer = value["correct_answer"]
            require(isinstance(answer, int) and 0 <= answer < value["option_count"], "legacy answer must be in range")
            require(value.get("difficulty", "unknown") != 0, "unknown difficulty cannot become zero")
            multi = value.get("correct_multi", None)
            if multi is None:
                require(value.get("answer_kind") == "single_choice", "absent/null correct_multi must not infer multiple_choice")
        elif subject == "draft_collection":
            drafts = case["value"]
            require(isinstance(drafts, list) and len(drafts) > 1, "draft collection expected")
            for draft in drafts: validate_draft(draft)
            ids = [draft["quiz_id"] for draft in drafts]
            require(len(ids) == len(set(ids)), "duplicate quiz_id")
        elif subject == "option_count":
            require(4 <= case["value"] <= 6, "choice questions require 4-6 options")
        else: raise ContractError("unknown negative subject")
    except ContractError:
        return name
    raise ContractError(f"negative fixture {name} unexpectedly accepted")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-summary", action="store_true")
    args = parser.parse_args()
    schemas = {path.name: load(path) for path in sorted(SCHEMAS.glob("*.json"))}
    validate_schema_declarations(schemas)
    positive = load(FIXTURES / "positive.json")
    negative = load(FIXTURES / "negative.json")
    scoring = load(FIXTURES / "scoring.json")
    validate_schema(positive["draft"], schemas["draft-quiz.schema.json"], schemas["draft-quiz.schema.json"], "positive.draft")
    validate_schema(positive["published_bundle"], schemas["published-bundle.schema.json"], schemas["published-bundle.schema.json"], "positive.published_bundle")
    for index, question in enumerate(positive["public_questions"]):
        validate_schema(question, schemas["public-question.schema.json"], schemas["public-question.schema.json"], f"positive.public_questions[{index}]")
    validate_schema(positive["reveal"], schemas["reveal.schema.json"], schemas["reveal.schema.json"], "positive.reveal")
    attempt_schema = schemas["attempts.schema.json"]
    validate_schema(positive["attempt"], attempt_schema, attempt_schema, "positive.attempt")
    validate_schema(positive["answer_write"], attempt_schema["$defs"]["answerWrite"], attempt_schema, "positive.answer_write")
    validate_schema(positive["attempt_finish"], attempt_schema["$defs"]["attemptFinish"], attempt_schema, "positive.attempt_finish")
    validate_schema(positive["room_event"], schemas["room-event.schema.json"], schemas["room-event.schema.json"], "positive.room_event")
    for index, error in enumerate(positive["errors"]):
        validate_schema(error, schemas["error-envelope.schema.json"], schemas["error-envelope.schema.json"], f"positive.errors[{index}]")
    validate_draft(positive["draft"])
    validate_published(positive["published_bundle"], positive["draft"])
    validate_public(positive["public_questions"][0]); validate_public(positive["public_questions"][1]); validate_public(positive["public_questions"][2])
    validate_reveal(positive["reveal"], positive["public_questions"], positive["draft"])
    validate_attempt(positive["attempt"], positive["public_questions"], positive["published_bundle"])
    validate_write(positive["answer_write"], positive["attempt"], positive["public_questions"])
    validate_finish(positive["attempt_finish"], positive["attempt"], positive["answer_write"])
    validate_room(positive["room_event"])
    for error in positive["errors"]: validate_error(error)
    validate_scoring(scoring["cases"])
    for legacy in positive["legacy_mappings"]:
        require(isinstance(legacy["correct_answer"], int) and 0 <= legacy["correct_answer"] < legacy["option_count"], "positive legacy answer mapping invalid")
        require(legacy["difficulty"] == "unknown" and legacy["answer_kind"] == "single_choice", "positive legacy unknown difficulty or type changed")
        require(legacy.get("correct_multi") is None, "positive legacy correct_multi must be absent/null")
    rejected = [validate_negative(case, positive, schemas) for case in negative["cases"]]
    expected = {"legacy_nonzero_mapping", "legacy_missing_answer", "legacy_negative_answer", "legacy_out_of_range_answer", "legacy_unknown_difficulty_zero", "duplicate_quiz_id", "duplicate_question_id", "absent_correct_multi", "null_correct_multi", "malformed_revision", "stale_reference", "stale_snapshot_revision", "bundle_hash_mismatch", "bundle_grading_mismatch", "attempt_bundle_mismatch", "reveal_wrong_option", "reveal_wrong_text", "write_tampered_digest", "write_answer_mismatch", "write_revision_mismatch", "secret_public_leak", "secret_public_is_correct", "secret_reveal_leak", "base_team_field", "base_team_event", "nested_team_field", "error_nested_secret", "write_participant_mismatch", "finish_missing_history_metadata", "too_few_options", "too_many_options", "schema_draft_option_secret", "schema_published_question_secret", "schema_private_grading_type", "schema_receipt_extra", "schema_option_map_type", "schema_error_detail_type"}
    require(set(rejected) == expected, "negative fixture coverage changed")
    summary = {"contract": "quiz-contract/v1", "positive_cases": 3, "negative_rejected": sorted(rejected), "scoring_cases": len(scoring["cases"]), "schema_files": sorted(schemas), "content_hash": digest({"schemas": schemas, "positive": positive, "negative": negative, "scoring": scoring})}
    output = json.dumps(summary, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    if args.write_summary:
        (ROOT / "summary.json").write_text(output + "\n", encoding="utf-8")
    print(output)


if __name__ == "__main__":
    try:
        main()
    except ContractError as exc:
        print(f"CONTRACT_ERROR: {exc}", file=sys.stderr)
        sys.exit(1)

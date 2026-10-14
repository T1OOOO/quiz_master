#!/usr/bin/env python3
"""Save acceptance only from an actual successful independent review trace."""
import argparse
import json
from pathlib import Path

import prepare_remote as remote
import prepare_screen_song_release as producer


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release-dir',type=Path,required=True)
    parser.add_argument('--trace',type=Path,required=True)
    parser.add_argument('--exit-json',type=Path,required=True)
    parser.add_argument('--task-id',required=True)
    parser.add_argument('--reviewer-provider',required=True,choices=('claude','anthropic','antigravity'), help='actual independent CLI runtime provider')
    args=parser.parse_args()
    if remote.load(args.exit_json).get('actual_exit') != 0:
        remote.fail('independent review process did not exit successfully')
    rows=[json.loads(line) for line in args.trace.read_text(encoding='utf-8').splitlines() if line.strip()]
    calls={};record=None
    for row in rows:
        message=row.get('message')
        if not isinstance(message,dict):
            continue
        for content in message.get('content',[]):
            if not isinstance(content,dict):
                continue
            if content.get('type')=='tool_use':
                calls[content['id']]=content
            if content.get('type')=='tool_result':
                call=calls.get(content.get('tool_use_id'),{})
                inputs=call.get('input',{});arguments=inputs.get('arguments',{})
                if (call.get('name','').endswith('hub_task') and inputs.get('action')=='review'
                        and arguments.get('task_id')==args.task_id and arguments.get('verdict')=='accept'
                        and not content.get('is_error',False)):
                    response=json.loads(content['content'])
                    candidate={'actual_hub_state':'ACCEPTED','actual_review':{'call':inputs,'actual_response':response}}
                    remote.require_actual_acceptance(candidate)
                    record=candidate['actual_review']
    if record is None:
        remote.fail('no actual independent ACCEPTED callback; no artifact written')
    final=next((row for row in reversed(rows) if row.get('type')=='result'),{})
    if final.get('is_error') is not False:
        remote.fail('successful final independent review result is absent')
    package,_=remote.reviewed_package(args.release_dir)
    execution=remote.load(args.release_dir/'execution-packet.json')
    if execution.get('package_sha256')!=package['archive_sha256'] or execution.get('build_id')!=remote.BUILD_ID or execution.get('source_commit')!=remote.SOURCE_COMMIT:
        remote.fail('reviewed execution package identity differs')
    result={'actual_hub_state':'ACCEPTED','actual_cli_exit':0,'reviewer_provider':args.reviewer_provider,'actual_review':record,
            'execution_packet_sha256':remote.sha(args.release_dir/'execution-packet.json'),
            'package_sha256':execution['package_sha256'],'image':execution['image'],
            'publish_script_sha256':execution['publish_script_sha256'],
            'publisher_controller_sha256':execution['publisher_controller_sha256'],
            'local_browser_evidence_sha256':execution['local_browser_evidence_sha256'],
            'trace_sha256':remote.sha(args.trace),'report':final.get('result'),
            'scope':'Actual independent acceptance of this exact prepared Screen Song image and publication command; no publication by this writer.'}
    producer.write_json_lf(args.release_dir/'execution-acceptance.json',result)
    print('Actual independent execution acceptance saved; no remote call executed.')


if __name__=='__main__':
    main()

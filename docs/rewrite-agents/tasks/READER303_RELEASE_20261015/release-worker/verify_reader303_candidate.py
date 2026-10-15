"""Invoke the established real candidate verifier with Reader-only count overrides."""
from __future__ import annotations
import argparse, importlib.util, runpy, sys
from pathlib import Path
HOUSE=Path(__file__).parents[5]/'docs/rewrite-agents/tasks/MIXED_RELEASE_20261014/worker/verify_candidate_runtime.py'
def load_house():
 s=importlib.util.spec_from_file_location('reader_house_runtime',HOUSE); assert s and s.loader; m=importlib.util.module_from_spec(s); s.loader.exec_module(m); return m
def verify_reader_bindings(reader,responses): return load_house().verify_reader_bindings(reader,responses,expected_articles=303,expected_total_refs=184,expected_playable_refs=182)
def verify_receipt(receipt,image): return load_house().verify_runtime_receipt(receipt,image,expected_packs=136,expected_questions=4084,expected_articles=303,expected_total_refs=184,expected_playable_refs=182)
def main():
 p=argparse.ArgumentParser(add_help=False); p.add_argument('--help',action='store_true'); a,rest=p.parse_known_args()
 if a.help: print('Pass through to established candidate verifier with Reader counts 303/184/182.'); return
 sys.argv=[str(HOUSE),*rest,'--expected-reader-articles','303','--expected-reader-total-refs','184','--expected-reader-playable-refs','182']; runpy.run_path(str(HOUSE),run_name='__main__')
if __name__=='__main__': main()

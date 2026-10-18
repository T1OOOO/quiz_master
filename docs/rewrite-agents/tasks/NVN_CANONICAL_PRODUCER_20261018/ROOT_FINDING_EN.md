# Blocking callback consistency finding on frozen first source

Root actually reproduced this on prepare_canonical.py rawSHA0201fcbc4fdb7dc7915bda4d9c53a1ebc160aace869000841ad05f5216d8d2b9. acceptance() checks integer error_count0 in ANY task-matching callback, then passes the original complete proof to inherited base.verify_acceptance(). That helper can choose a DIFFERENT accepted callback whose error_count is boolFalse, because False==0 in Python.

A disposable explicit SYNTHETIC_ROOT_PROBE_ONLY proof contained an integer0/rework callback and a boolFalse/accept callback, both with the same task ID. The actual new acceptance function and actual inherited helper accepted it: ACCEPTS_MIXED_BOOL_CALLBACK. There was no actual release acceptance, source edit, archive or server operation. The synthetic proof remains ignored scratch only.

Smallest correction: bind integer-zero validation to the same accepted callback used by the inherited validator. Filtering a copied proof's actual_reviews to integer-typed zero task callbacks before passing it to the existing validator avoids duplicating all acceptance logic. Add an exact mixed-callback regression and rerun checks; obtain genuine changed-source independent review. Any first-pass accept does not resolve this Root finding. Do not change frozen source while the current reviewer is reading it.

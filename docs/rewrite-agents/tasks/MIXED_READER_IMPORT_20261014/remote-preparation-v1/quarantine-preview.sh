set -euo pipefail
test "$(hostname)" = racknerd-f0269d5
exec 8>/opt/quiz-master/DEPLOY.lock
flock -n 8
test "$(readlink -f /opt/quiz-master/releases)" = /opt/quiz-master/releases
test "$(kubectl get deploy quiz-master -n quiz-master -o jsonpath='{.spec.template.spec.containers[0].image}')" = docker.io/library/quiz-master@sha256:2d1ea6bcb0f92bf62b7173bb23ff0133cfd457ebd4746f08cbcdd73e3f221727
helm status quiz-master -n quiz-master -o json | python3 -c 'import json,sys;x=json.load(sys.stdin);assert x["version"]==53 and x["info"]["status"]=="deployed"'
test -z "$(ss -ltnH 'sport = :18088')"
quiz_failed=/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce
quiz_saved=/opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce-failed-20261014T153204Z
test "$(readlink -f "$quiz_failed")" = "$quiz_failed"
test ! -L "$quiz_failed"
test ! -e "$quiz_failed/candidate-runtime-verification.json"
test ! -e "$quiz_saved"
test ! -e "$quiz_saved.tar.gz"
test ! -L "$quiz_failed.tar.gz"
echo '052791b502cc068c57831473ff200cbd8fdc756018942c500508ca81a0b7f872  /opt/quiz-master/releases/quiz-2026.10.14-reader-17be4ce.tar.gz' | sha256sum -c -
mv -- "$quiz_failed" "$quiz_saved"
mv -- "$quiz_failed.tar.gz" "$quiz_saved.tar.gz"
printf 'OWNED_FAILED_STAGE_QUARANTINED_BACKUPS_RETAINED\n'

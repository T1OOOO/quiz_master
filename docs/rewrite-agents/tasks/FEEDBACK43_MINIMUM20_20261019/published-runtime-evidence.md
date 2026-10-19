# Published minimum20 release: actual runtime evidence

The independently accepted receipt was published with the reviewed controller. Publish process completed with exit0. Helm70 / Deployment68 is running the immutable09cc image in both API/webcontainers. Rollback target remains69.

The controller refreshed the live backup, verified restore integrity, completed atomic Helm upgrade and rollout, matched public version and JavaScript SHA, checked readiness/liveness, preserved the PVC UID and all66 original feedback rows. Originalreport26 remainsOPEN pending independentpublicoutcome acceptance.

Publish transcript SHA256: `1de4d518c27452fa84c711cb5ab145c05362f6960db5e9de61f5e31fa48dc904`.

```text
{'evictionHard': {'imagefs.available': '5%', 'nodefs.available': '5%'}, 'evictionMinimumReclaim': {'imagefs.available': '10%', 'nodefs.available': '10%'}, 'imageGCHighThresholdPercent': 85, 'imageGCLowThresholdPercent': 80}
{'evictionHard': {'imagefs.available': '5%', 'nodefs.available': '5%'}, 'evictionMinimumReclaim': {'imagefs.available': '10%', 'nodefs.available': '10%'}, 'imageGCHighThresholdPercent': 85, 'imageGCLowThresholdPercent': 80}
Release "quiz-master" has been upgraded. Happy Helming!
NAME: quiz-master
LAST DEPLOYED: Mon Oct 19 20:34:11 2026
NAMESPACE: quiz-master
STATUS: deployed
REVISION: 70
TEST SUITE: None
deployment "quiz-master" successfully rolled out
```

Post-publication fresh imageFS availability: 21.073569540916598%; nodeReady and all pressureconditionsfalse. Runningpod/API SHA and unchanged kubeletcapacitysettings are in `published-pod-evidence.json`. Root publiccatalog/alias/JS checks and mobilepublicchecks are recorded separately.

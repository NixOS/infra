#! /usr/bin/env python
import checks
import requests
import json


class HydraCheck(checks.AgentCheck):
    def check(self, instance):
        r = requests.get(
            "http://localhost:3000/status", headers={"Content-Type": "application/json"}
        )
        self.gauge("hydra.active_buildsteps", len(json.loads(r.text)))

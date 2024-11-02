import json

import requests

import checks


class HydraCheck(checks.AgentCheck):
    def check(self, instance) -> None:
        r = requests.get(
            "http://localhost:3000/status", headers={"Content-Type": "application/json"}
        )
        self.gauge("hydra.active_buildsteps", len(json.loads(r.text)))

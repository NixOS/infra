#! /usr/bin/env python
from checks import *
import os
import subprocess
import requests
import json


class HydraCheck(AgentCheck):
    def check(self, instance):
        r = requests.get(
            "http://localhost:3000/status", headers={"Content-Type": "application/json"}
        )
        self.gauge("hydra.active_buildsteps", len(json.loads(r.text)))

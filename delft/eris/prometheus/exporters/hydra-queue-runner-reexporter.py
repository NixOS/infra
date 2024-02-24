#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 -p python3Packages.requests -p python3Packages.prometheus_client

import requests
import json
from prometheus_client.core import GaugeMetricFamily, CounterMetricFamily
from prometheus_client import CollectorRegistry, generate_latest, start_http_server
from pprint import pprint
import time

def debug_remaining_state(edict):
    # pprint(edict.remaining_state())
    pass

class EvaporatingDict:
    def __init__(self, state):
        self._state = state

    def preserving_read(self, key):
        val = self._state[key]

        if type(val) is dict:
            return EvaporatingDict(val)
        else:
            return val

    def preserving_read_default(self, key, default):
        try:
            val = self.preserving_read(key)
            return val
        except KeyError:
            return default

    def destructive_read(self, key):
        val = self.preserving_read(key)
        del self._state[key]
        return val

    def destructive_read_default(self, key, default):
        try:
            val = self.preserving_read(key)
            del self._state[key]
            return val
        except KeyError:
            # Not nice, but accounts for weird conditionals in Hydra
            # todo: log bad reads?
            return default

    def unused_read(self, key):
        self.destructive_read_default(key, default=None)

    def remaining_state(self):
        return self._state

    def items(self):
        keys = list(self._state.keys())
        for key in keys:
            yield (key, self.destructive_read(key))

class HydraScrapeImporter:
    def __init__(self, status):
        self._status = EvaporatingDict(status)

    def collect(self):
        # The metrics are consumed in the order presented by
        # https://github.com/NixOS/hydra/blob/adf59a395993d5ed1d7a31108f7666195f789c99/src/hydra-queue-runner/hydra-queue-runner.cc#L536
        yield self.trivial_gauge(
            "up",
            "Is hydra running",
            1 if self.destructive_read("status") == "up" else 0
        )
        yield self.trivial_counter(
            "time",
            "Hydra's current time",
            self.destructive_read("time")
        )
        yield self.trivial_counter(
            "uptime",
            "Hydra's uptime",
            self.destructive_read("uptime")
        )
        self.unused_metric("pid")
        yield self.trivial_gauge(
            "builds_queued",
            "Current build queue size",
            self.destructive_read("nrQueuedBuilds")
        )
        yield self.trivial_gauge(
            "steps_queued",
            "Current number of steps for the build queue",
            self.destructive_read("nrUnfinishedSteps")
        )
        yield self.trivial_gauge(
            "steps_runnable",
            "Current number of steps which can run immediately",
            self.destructive_read("nrRunnableSteps")
        )
        yield self.trivial_gauge(
            "steps_active",
            "Current number of steps which are currently active",
            self.destructive_read("nrActiveSteps")
        )
        yield self.trivial_gauge(
            "steps_building",
            "Current number of steps which are currently building",
            self.destructive_read("nrStepsBuilding")
        )
        yield self.trivial_gauge(
            "steps_copying_to",
            "Current number of steps which are having build inputs copied to a builder",
            self.destructive_read("nrStepsCopyingTo")
        )
        yield self.trivial_gauge(
            "steps_copying_from",
            "Current number of steps which are having build results copied from a builder",
            self.destructive_read("nrStepsCopyingFrom")
        )
        yield self.trivial_gauge(
            "steps_waiting",
            "Current number of steps which are waiting",
            self.destructive_read("nrStepsWaiting")
            )
        yield self.trivial_counter(
            "build_inputs_sent_bytes",
            "Total count of bytes sent due to build inputs",
            self.destructive_read("bytesSent")
        )
        yield self.trivial_counter(
            "build_outputs_received_bytes",
            "Total count of bytes received from build outputs",
            self.destructive_read("bytesReceived")
        )
        yield self.trivial_counter(
            "builds_read",
            "Total count of builds whose outputs have been read",
            self.destructive_read("nrBuildsRead")
        )
        yield self.trivial_counter(
            "builds_read_seconds",
            "Total number of seconds spent reading build outputs",
            self.destructive_read("buildReadTimeMs") / 1000
        )
        self.unused_metric("buildReadTimeAvgMs") # implementable in prometheus queries

        yield self.trivial_counter(
            "builds_done",
            "Total count of builds performed",
            self.destructive_read("nrBuildsDone")
        )
        yield self.trivial_counter(
            "steps_started",
            "Total count of steps started",
            self.destructive_read("nrStepsStarted")
        )
        yield self.trivial_counter(
            "steps_done",
            "Total count of steps completed",
            self.destructive_read("nrStepsDone")
        )
        yield self.trivial_counter(
            "retries",
            "Total count of retries",
            self.destructive_read("nrRetries")
        )
        yield self.trivial_counter(
            "max_retries",
            "Maximum count of retries for any single job",
            self.destructive_read("maxNrRetries")
        )
        yield self.trivial_counter(
            "step_time",
            "Total time spent executing steps",
            self.destructive_read_default("totalStepTime", 0)
        )
        yield self.trivial_counter(
            "step_build_time",
            "Total time spent executing builds steps (???)",
            self.destructive_read_default("totalStepBuildTime", 0)
        )
        self.unused_metric("avgStepTime")
        self.unused_metric("avgStepBuildTime")

        yield self.trivial_counter(
            "queue_wakeup",
            "Count of the times the queue runner has been notified of queue changes",
            self.destructive_read("nrQueueWakeups")
        )
        yield self.trivial_counter(
            "dispatcher_wakeup",
            "Count of the times the queue runner work dispatcher woke up due to new runnable builds and completed builds.",
            self.destructive_read("nrDispatcherWakeups")
        )
        yield self.trivial_counter(
            "dispatch_execution_seconds",
            "Number of seconds the dispatcher has spent working",
            self.destructive_read("dispatchTimeMs") / 1000
        )
        self.unused_metric("dispatchTimeAvgMs")

        yield self.trivial_gauge(
            "db_connections",
            "Number of connections to the database",
            self.destructive_read("nrDbConnections")
        )
        yield self.trivial_gauge(
            "db_updates",
            "Number of in-progress database updates",
            self.destructive_read("nrActiveDbUpdates")
        )
        yield self.trivial_counter(
            "notifications_total",
            "Total number of notifications sent",
            self.preserving_read_default("nrNotificationsDone", 0) +
            self.preserving_read_default("nrNotificationsFailed", 0)
        )
        yield self.trivial_counter(
            "notifications_done",
            "Number of notifications completed",
            self.destructive_read_default("nrNotificationsDone", 0)
        )
        yield self.trivial_counter(
            "notifications_failed",
            "Number of notifications failed",
            self.destructive_read_default("nrNotificationsFailed", 0)
        )
        yield self.trivial_counter(
            "notifications_in_progress",
            "Number of notifications in_progress",
            self.destructive_read_default("nrNotificationsInProgress", 0)
        )
        yield self.trivial_counter(
            "notifications_pending",
            "Number of notifications pending",
            self.destructive_read_default("nrNotificationsPending", 0)
        )
        yield self.trivial_counter(
            "notifications_seconds",
            "Time spent delivering notifications",
            self.destructive_read_default("nrNotificationTimeMs", 0) / 1000
        )
        self.unused_metric("nrNotificationTimeAvgMs")

        machineCollector = MachineScrapeImporter()
        for name, report in self.destructive_read("machines").items():
            machineCollector.load_machine(name, report)
        for metric in machineCollector.metrics():
            yield metric

        jobsetCollector = JobsetScrapeImporter()
        for name, report in self.destructive_read("jobsets").items():
            jobsetCollector.load_jobset(name, report)
        for metric in jobsetCollector.metrics():
            yield metric

        machineTypesCollector = MachineTypeScrapeImporter()
        for name, report in self.destructive_read("machineTypes").items():
            machineTypesCollector.load_machine_type(name, report)
        for metric in machineTypesCollector.metrics():
            yield metric

        store = self.destructive_read("store")
        yield self.trivial_counter(
            "store_nar_info_read",
            "Number of NarInfo files read from the binary cache",
            store.destructive_read("narInfoRead")
        )
        yield self.trivial_counter(
            "store_nar_info_read_averted",
            "Number of NarInfo files reads which were avoided",
            store.destructive_read("narInfoReadAverted")
        )
        yield self.trivial_counter(
            "store_nar_info_missing",
            "Number of NarInfo files read attempts which identified a missing narinfo file",
            store.destructive_read("narInfoMissing")
        )
        yield self.trivial_counter(
            "store_nar_info_write",
            "Number of NarInfo files written to the binary cache",
            store.destructive_read("narInfoWrite")
        )
        yield self.trivial_gauge(
            "store_nar_info_cache_size",
            "Size of the in-memory store path information cache",
            store.destructive_read("narInfoCacheSize")
        )
        yield self.trivial_counter(
            "store_nar_read",
            "Number of NAR files read from the binary cache",
            store.destructive_read("narRead")
        )
        yield self.trivial_counter(
            "store_nar_read_bytes",
            "Number of NAR file bytes read after decompression from the binary cache",
            store.destructive_read("narReadBytes")
        )
        yield self.trivial_counter(
            "store_nar_read_compressed_bytes",
            "Number of NAR file bytes read before decompression from the binary cache",
            store.destructive_read("narReadCompressedBytes")
        )
        yield self.trivial_counter(
            "store_nar_write",
            "Number of NAR files written to the binary cache",
            store.destructive_read("narWrite")
        )
        yield self.trivial_counter(
            "store_nar_write_averted",
            "Number of NAR files writes skipped due to the NAR already being in the binary cache",
            store.destructive_read("narWriteAverted")
        )
        yield self.trivial_counter(
            "store_nar_write_bytes",
            "Number of NAR file bytes written after decompression to the binary cache",
            store.destructive_read("narWriteBytes")
        )
        yield self.trivial_counter(
            "store_nar_write_compressed_bytes",
            "Number of NAR file bytes written before decompression to the binary cache",
            store.destructive_read("narWriteCompressedBytes")
        )
        yield self.trivial_counter(
            "store_nar_write_compression_seconds",
            "Number of seconds spent compressing data when writing NARs to the binary cache",
            store.destructive_read("narWriteCompressionTimeMs") / 1000
        )
        store.unused_read("narCompressionSavings")
        store.unused_read("narCompressionSpeed")

        try:
            s3 = self.destructive_read("s3")
        except KeyError:
            # no key, no metrics
            s3 = None
            pass
        if s3:
            # Not in the above try to avoid the try catching mistakes
            # in the following code
            yield self.trivial_counter(
                "store_s3_put",
                "Number of PUTs to S3",
                s3.destructive_read("put")
            )
            yield self.trivial_counter(
                "store_s3_put_bytes",
                "Number of bytes written to S3",
                s3.destructive_read("putBytes")
            )
            yield self.trivial_counter(
                "store_s3_put_seconds",
                "Number of seconds spent writing to S3",
                s3.destructive_read("putTimeMs") / 1000
            )
            s3.unused_read("putSpeed")
            yield self.trivial_counter(
                "store_s3_get",
                "Number of GETs to S3",
                s3.destructive_read("get")
            )
            yield self.trivial_counter(
                "store_s3_get_bytes",
                "Number of bytes read from S3",
                s3.destructive_read("getBytes")
            )
            yield self.trivial_counter(
                "store_s3_get_seconds",
                "Number of seconds spent reading from S3",
                s3.destructive_read("getTimeMs") / 1000
            )
            s3.unused_read("getSpeed")

            yield self.trivial_counter(
                "store_s3_head",
                "Number of HEADs to S3",
                s3.destructive_read("head")
            )
            yield self.trivial_counter(
                "store_s3_cost_approximate_dollars",
                "Estimated cost of the S3 bucket activity",
                s3.destructive_read("costDollarApprox")
            )
            debug_remaining_state(s3)
        debug_remaining_state(store)

    def trivial_gauge(self, name, help, value):
        c = GaugeMetricFamily(f"hydra_{name}", help)
        c.add_metric([], value)
        return c

    def trivial_counter(self, name, help, value):
        c = CounterMetricFamily(f"hydra_{name}_total", help)
        c.add_metric([], value)
        return c

    def unused_metric(self, key):
        self._status.unused_read(key)

    def preserving_read(self, key):
        return self._status.preserving_read(key)

    def preserving_read_default(self, key, default):
        return self._status.preserving_read_default(key, default)

    def destructive_read(self, key):
        return self._status.destructive_read(key)

    def destructive_read_default(self, key, default):
        return self._status.destructive_read_default(key, default)

    def uncollected_status(self):
        return self._status.remaining_state()

def blackhole(*args, **kwargs):
    return None

class MachineScrapeImporter:
    def __init__(self):
        labels = [ "host" ]
        self.consective_failures = GaugeMetricFamily(
            "hydra_machine_consecutive_failures",
            "Number of consecutive failed builds",
            labels=labels)
        self.current_jobs = GaugeMetricFamily(
            "hydra_machine_current_jobs",
            "Number of current jobs",
            labels=labels)
        self.idle_since = GaugeMetricFamily(
            "hydra_machine_idle_since",
            "When the current idle period started",
            labels=labels)
        self.disabled_until = GaugeMetricFamily(
            "hydra_machine_disabled_until",
            "When the machine will be used again",
            labels=labels)
        self.enabled = GaugeMetricFamily(
            "hydra_machine_enabled",
            "If the machine is enabled (1) or not (0)",
            labels=labels)
        self.last_failure = CounterMetricFamily(
            "hydra_machine_last_failure",
            "timestamp of the last failure",
            labels=labels)
        self.number_steps_done = CounterMetricFamily(
            "hydra_machine_steps_done_total",
            "Total count of the steps completed",
            labels=labels)
        self.total_step_build_time = CounterMetricFamily(
            "hydra_machine_step_build_time_total",
            "Number of seconds spent building steps",
            labels=labels)
        self.total_step_time = CounterMetricFamily(
            "hydra_machine_step_time_total",
            "Number of seconds spent on steps",
            labels=labels)

    def load_machine(self, name, report):
        report.unused_read("mandatoryFeatures")
        report.unused_read("supportedFeatures")
        report.unused_read("systemTypes")
        report.unused_read("avgStepBuildTime")
        report.unused_read("avgStepTime")
        labels = [name]
        self.consective_failures.add_metric(
            labels,
            report.destructive_read("consecutiveFailures")
        )
        self.current_jobs.add_metric(
            labels,
            report.destructive_read("currentJobs")
        )
        try:
            self.idle_since.add_metric(
                labels,
                report.destructive_read("idleSince")
            )
        except KeyError:
            pass
        self.disabled_until.add_metric(
            labels,
            report.destructive_read("disabledUntil")
        )
        self.enabled.add_metric(
            labels,
            1 if report.destructive_read("enabled") else 0
        )
        self.last_failure.add_metric(
            labels,
            report.destructive_read("lastFailure")
        )
        self.number_steps_done.add_metric(
            labels,
            report.destructive_read("nrStepsDone")
        )
        self.total_step_build_time.add_metric(
            labels,
            report.destructive_read_default("totalStepBuildTime", default=0)
        )
        self.total_step_time.add_metric(
            labels,
            report.destructive_read_default("totalStepTime", default=0)
        )
        debug_remaining_state(report)
    def metrics(self):
        yield self.consective_failures
        yield self.current_jobs
        yield self.idle_since
        yield self.disabled_until
        yield self.enabled
        yield self.last_failure
        yield self.number_steps_done
        yield self.total_step_build_time
        yield self.total_step_time


class JobsetScrapeImporter:
    def __init__(self):
        self.seconds = CounterMetricFamily(
            "hydra_jobset_seconds_total",
            "Total number of seconds the jobset has been building",
            labels=["name"])
        self.shares_used = CounterMetricFamily(
            "hydra_jobset_shares_used_total",
            "Total shares the jobset has consumed",
            labels=["name"])

    def load_jobset(self, name, report):
        self.seconds.add_metric([name], report.destructive_read("seconds"))
        self.shares_used.add_metric([name], report.destructive_read("shareUsed"))
        debug_remaining_state(report)

    def metrics(self):
        yield self.seconds
        yield self.shares_used


class MachineTypeScrapeImporter:
    def __init__(self):
        self.runnable = GaugeMetricFamily(
            "hydra_machine_type_runnable",
            "Number of currently runnable builds",
            labels=["machineType"])
        self.running = GaugeMetricFamily(
            "hydra_machine_type_running",
            "Number of currently running builds",
            labels=["machineType"])
        self.wait_time = CounterMetricFamily(
            "hydra_machine_type_wait_time_total",
            "Number of seconds spent waiting",
            labels=["machineType"])
        self.last_active = CounterMetricFamily(
            "hydra_machine_type_last_active_total",
            "Last time this machine type was active",
            labels=["machineType"])


    def load_machine_type(self, name, report):
        self.runnable.add_metric([name], report.destructive_read("runnable"))
        self.running.add_metric([name], report.destructive_read("running"))
        try:
            self.wait_time.add_metric([name], report.destructive_read("waitTime"))
        except KeyError:
            pass
        try:
            self.last_active.add_metric([name], report.destructive_read("lastActive"))
        except KeyError:
            pass

        debug_remaining_state(report)

    def metrics(self):
        yield self.runnable
        yield self.running
        yield self.wait_time
        yield self.last_active

class ScrapeCollector:
    def __init__(self):
        pass

    def collect(self):
        return HydraScrapeImporter(scrape()).collect()

def scrape(cached=None):
    if cached:
        with open(cached) as f:
            return json.load(f)
    else:
        print("Scraping")
        return requests.get(
            'https://hydra.nixos.org/queue-runner-status',
            headers={
                "Content-Type": "application/json"
            }
        ).json()

registry = CollectorRegistry()

registry.register(ScrapeCollector())

if __name__ == '__main__':
    # Start up the server to expose the metrics.
    start_http_server(9200, registry=registry)
    # Generate some requests.
    while True:
        time.sleep(30)

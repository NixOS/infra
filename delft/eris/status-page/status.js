function init() {
  return new Promise(resolve => {
    window.onload = () => {
      var tbody = document.getElementById("channel-status");
      tbody.innerHTML = "<tr><td class='jsfallback' colspan='5'>Loading data from Prometheus...</td></tr>";
      resolve();
    };
  });
}

function aggregateByChannel(result) {
  return result.reduce((acc, {
    channel,
    value
  }) => ({
    ...acc,
    [channel]: value
  }), {});
}

async function fetchData(queryType, queryArgs = {}) {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(queryArgs)) {
    params.set(key, String(value));
  }

  const response = await fetch(`https://status.nixos.org/prometheus/api/v1/${queryType}?${params}`);
  const {
    data
  } = await response.json();

  return data.result;
}

const revisionData = fetchData('query', {
    query: 'channel_revision'
  })
  .then(records => (
    records.map(({
      metric
    }) => ({
      channel: metric.channel,
      value: {
        revision: metric.revision,
        short_revision: metric.revision.substring(0, 12),
        github_url: `https://github.com/NixOS/nixpkgs/commit/${metric.revision}`,
      },
    }))
  ))
  .then(aggregateByChannel);


const updateTimeData = fetchData('query', {
    query: 'channel_update_time'
  })
  .then(records => (
    records.map(({
      metric,
      value
    }) => ({
      channel: metric.channel,
      value: {
        update_time: value[1],
      },
    }))
  ))
  .then(aggregateByChannel);

var earliestStart = moment.utc("2019-12-30T01:00:00Z");
var idealStart = moment.utc().subtract(30, "days");
var start;
if (idealStart > earliestStart) {
    start = idealStart;
} else {
    start = earliestStart;
}
var end = moment.utc().format();
const jobsetData = fetchData('query_range', {
    query: 'hydra_job_failed',
    start: start.format(),
    end,
    step: '1h'
  })
  .then(records => (
    records.map(({
      metric,
      values
    }) => {
      const project = metric.project;
      const jobset = metric.jobset;
      const job = metric.exported_job;

      return {
        channel: metric.channel,
        value: {
          current: metric.current == 1,
          project,
          jobset,
          job,
          job_history: values.map(state => state[1] == 0),
          oldest_status: values[0][0],
          hydra_url: `https://hydra.nixos.org/job/${project}/${jobset}/${job}`,
        },
      };
    })
  ))
  .then(aggregateByChannel);

function split_channel(channel) {
  var parts = channel.split("-");
  return {
    "time": parts[1],
    "collection": parts[0],
    "qualifier": parts[2] || "",
  }
}

function normalize_channel(channel) {
  parts = split_channel(channel);
  return [parts['time'], parts['collection'], parts['qualifier']].join("-");
}

function cmp_channels(left, right) {
  return normalize_channel(left) < normalize_channel(right)
}

init()
  .then(() => Promise.all([revisionData, updateTimeData, jobsetData]))
  .then(([revisions, update_times, jobsets]) => {
    var combined = [];

    for (let [channel, jobset] of Object.entries(jobsets)) {
      jobset['oldest_status_relative'] = moment.unix(jobset['oldest_status']).fromNow()
      // Ensure each jobset here is in each other dataset, guaranteeing we have
      // complete data.
      jobset['channel'] = channel;
      if (revisions[channel] != undefined) {
        jobset['revision'] = revisions[channel]['revision'];
        jobset['short_revision'] = revisions[channel]['short_revision'];
        jobset['github_url'] = revisions[channel]['github_url'];
      } else {
        continue
      }
      if (update_times[channel] != undefined) {
        var m = moment.unix(update_times[channel]['update_time']);
        jobset['update_time_relative'] = m.fromNow()
        jobset['update_time_local'] = m.format()
        if (m > moment().subtract(3, 'days')) {
          jobset['update_age'] = "success";
        } else if (m > moment().subtract(10, 'days')) {
          jobset['update_age'] = "warning";
        } else {
          jobset['update_age'] = "important";
        }
      } else {
        continue
      }

      combined.push(jobset);
    }

    combined.sort((left, right) => cmp_channels(left['channel'], right['channel']));

    return combined;
  })
  .then(data => {
    return data.map(record => {
      var row = document.createElement('tr');
      row.innerHTML = '<td class="channel" /><td><span class="age label"></span></td><td class="github"><a class="revision" /></td><td class="hydra"><a class="hydra-link" /></td><td class="status"></td>';
      if (record['current']) {
        row.classList.add("current")
      } else {
        row.classList.add("stale")
        row.getElementsByClassName("status")[0].innerHTML += '<span class="label label-important">End of life</span>';
      }
      row.getElementsByClassName("channel")[0].innerText = record['channel'];

      row.getElementsByClassName("age")[0].innerText = record['update_time_relative'];
      row.getElementsByClassName("age")[0].title = record['update_time_local'];
      row.getElementsByClassName("age")[0].classList.add("label-" + record['update_age']);
      row.getElementsByClassName("revision")[0].innerText = record['short_revision'];
      row.getElementsByClassName("revision")[0].href = record['github_url'];

      row.getElementsByClassName("hydra-link")[0].href = record['hydra_url'];
      row.getElementsByClassName("hydra-link")[0].innerText = [record['project'], record['jobset'], record['job']].join('/');
      row.getElementsByClassName("hydra")[0].style.backgroundImage = "linear-gradient(to right, " +
        (record['job_history'].map(val => val ? "#b5ffb5" : "#ff9e9e")).join(", ") +
        ")";
      row.getElementsByClassName("hydra")[0].title = `The Hydra job's state over time, since ${record['oldest_status_relative']}`;

      if (record['job_history'][record['job_history'].length - 1] == 0) {
        row.getElementsByClassName("status")[0].innerHTML += '<span class="label label-important">Build problem</span>';

      }
      return row;
    })
  })
  .then(rows => {
    var tbody = document.getElementById("channel-status");
    tbody.innerHTML = "";
    rows.forEach(row => {
      tbody.appendChild(row);
    });
  });

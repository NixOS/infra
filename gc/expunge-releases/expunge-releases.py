from datetime import datetime
import os
import re
import sys

release_dirs = ["nixos", "nixpkgs"]

name_to_release = re.compile('(nixos|nixpkgs)-(darwin-)?(\d\d.\d\d)')
version_split = re.compile('-|\.|alpha|beta|pre')
is_prerelease = re.compile('alpha|beta|pre')

minimum_release_to_keep = "23.05"

def log(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

class FileEntry:
    def __init__(self, date, size, key):
        self.date = date
        self.size = size
        self.key = key

def parse_file(filename):
    entries = []
    with open(filename, 'r') as file:
        for line in file:
            #date = datetime.strptime(line[0:19], "%Y-%m-%d %H:%M:%S")
            date = None # don't need it
            size = int(line[19:31])
            key = line[31:].rstrip('\n')
            entry = FileEntry(date, size, key)
            entries.append(entry)
    return entries

class Release:
    def __init__(self, name, date):
        self.name = name
        self.date = date
        self.files = []

    def major_release(self):
        basename = os.path.basename(self.name)
        m = name_to_release.match(basename)
        return m[3] if m else None

    def sort_key(self):
        # Prereleases get sorted before non-prereleases.
        # Pad integer components to compare them numerically.
        name = os.path.basename(self.name)
        return [not re.search(is_prerelease, name)] + [maybe_pad_int(s) for s in re.split(version_split, name)]

def maybe_pad_int(s):
    return s.zfill(10) if s.isdigit() else s

releases = dict()

filename = "bucket-contents"
file_entries = parse_file(filename)

# Gather all releases. These are identified by having a "src-url" file
# in them.
for entry in file_entries:
    if entry.key.endswith("src-url"):
        #log("Date:", entry.date, "Size:", entry.size, "Name:", entry.key)
        name = os.path.dirname(entry.key)
        releases[name] = Release(name, entry.date)

# Get the files for each release.
for entry in file_entries:
    rel_name = os.path.dirname(entry.key)
    rel = releases.get(rel_name)
    if rel is not None:
        rel.files.append(entry)

log("Found {} releases.".format(len(releases)))

# Group the releases by parent directory (like nixpkgs/23.11-darwin/).
release_parents = dict()

for rel in releases.values():
    parent_dir = os.path.dirname(rel.name)
    release_parents.setdefault(parent_dir, []).append(rel)

# For each parent directory, group the releases by major release
# (e.g. 23.11).
expunged_releases = 0
expunged_files = 0
expunged_size = 0

for release_parent_name, rels in release_parents.items():
    major_releases = dict()
    for rel in rels:
        major_release = rel.major_release()
        if major_release is None:
            log("Skipping release '{}'.".format(rel.name))
        else:
            major_releases.setdefault(major_release, []).append(rel)

    for major_release_name, rels in major_releases.items():
        if major_release_name >= minimum_release_to_keep:
            log("Keeping all {} releases in major release group '{}/{}'.".format(len(rels), release_parent_name, major_release_name))
        else:
            # Sort the releases by release name (lexicographically after splitting into version components), keep the newest one.
            sorted_rels = sorted(rels, key=lambda rel: rel.sort_key())
            log("Major release group '{}/{}' ({} releases).".format(release_parent_name, major_release_name, len(rels)))
            #for rel in sorted_rels:
            #    log("  ", rel.date, rel.name, rel.sort_key())

            # Keep the most recent release in the group.
            most_recent_rel = sorted_rels.pop()

            # Expunge the other releases.
            for rel in sorted_rels:
                rel_size = sum([f.size for f in rel.files])
                log("  Expunging release '{}' ({} files, {:.2f} MiB).".format(rel.name, len(rel.files), rel_size / 1024**2))
                for f in rel.files:
                    print(f.key)
                expunged_releases += 1
                expunged_files += len(rel.files)
                expunged_size += rel_size

            log("  Keeping release '{}'.".format(most_recent_rel.name))

log("Expunged {} releases, {} files, {:.2f} GiB.".format(expunged_releases, expunged_files, expunged_size / 1024**3))

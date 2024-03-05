from datetime import datetime
import os
import re

release_dirs = ["nixos", "nixpkgs"]

name_to_release = re.compile('(nixos|nixpkgs)-(darwin-)?(\d\d.\d\d)')
version_split = re.compile('-|\.|alpha|beta|pre')
is_prerelease = re.compile('alpha|beta|pre')

minimum_release_to_keep = "23.05"

class FileEntry:
    def __init__(self, date, size, name):
        self.date = date
        self.size = size
        self.name = name

def parse_file(filename):
    entries = []
    with open(filename, 'r') as file:
        for line in file:
            #date = datetime.strptime(line[0:19], "%Y-%m-%d %H:%M:%S")
            date = None # don't need it
            size = int(line[19:31])
            name = line[31:].rstrip('\n')
            entry = FileEntry(date, size, name)
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
    if entry.name.endswith("src-url"):
        #print("Date:", entry.date, "Size:", entry.size, "Name:", entry.name)
        name = os.path.dirname(entry.name)
        releases[name] = Release(name, entry.date)

# Get the files for each release.
for entry in file_entries:
    rel_name = os.path.dirname(entry.name)
    rel = releases.get(rel_name)
    if rel is not None:
        rel.files.append(entry)

print("Found {} releases.".format(len(releases)))

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
            print("Skipping release '{}'.".format(rel.name))
        else:
            major_releases.setdefault(major_release, []).append(rel)

    for major_release_name, rels in major_releases.items():
        if major_release_name >= minimum_release_to_keep:
            print("Keeping all {} releases in major release group '{}/{}'.".format(len(rels), release_parent_name, major_release_name))
        else:
            # Sort the releases by release name (lexicographically after splitting into version components), keep the newest one.
            sorted_rels = sorted(rels, key=lambda rel: rel.sort_key())
            print("Major release group '{}/{}' ({} releases).".format(release_parent_name, major_release_name, len(rels)))
            #for rel in sorted_rels:
            #    print("  ", rel.date, rel.name, rel.sort_key())

            # Keep the most recent release in the group.
            most_recent_rel = sorted_rels.pop()

            # Expunge the other releases.
            for rel in sorted_rels:
                rel_size = sum([f.size for f in rel.files])
                print("  Expunging release '{}' ({} files, {:.2f} MiB).".format(rel.name, len(rel.files), rel_size / 1024**2))
                #for f in rel.files:
                #    print("    {}".format(f.name))
                #    # TODO: delete or move to glacier.
                expunged_releases += 1
                expunged_files += len(rel.files)
                expunged_size += rel_size

            print("  Keeping release '{}'.".format(most_recent_rel.name))

print("Expunged {} releases, {} files, {:.2f} GiB.".format(expunged_releases, expunged_files, expunged_size / 1024**3))

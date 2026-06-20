#! /usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Digest::SHA;
use Fcntl qw(:flock);
use File::Basename;
use File::Path;
use File::Slurp;
use File::stat;
use JSON::PP;
use LWP::UserAgent;
use List::MoreUtils qw(uniq);
use Net::Amazon::S3;
use POSIX qw(strftime);

# Runs the given command, printing the (unescaped) command.
# This command continues on failure.
sub runAllowFailure {
    print STDERR " \$ ", join(" ", @_), "\n";
    system(@_);
}

# Runs the given command, printing the (unescaped) command.
# This command dies on failure.
sub run {
    my $context = caller(0);
    my $code = runAllowFailure(@_);
    unless ($code == 0) {
        my $exit = $code >> 8;
        my $errno = $code - ($exit << 8);
        die "Command failed with code ($exit) errno ($errno).\n";
    }

    return $code;
}

my $channelName = $ARGV[0];
my $releaseUrl = $ARGV[1];

die "Usage: $0 CHANNEL-NAME RELEASE-URL\n" unless defined $channelName && defined $releaseUrl;

$channelName =~ /^([a-z]+)-(.*)$/ or die;
my $channelDirRel = $channelName eq "nixpkgs-unstable" ? "nixpkgs" : "$1/$2";


# Configuration.
my $TMPDIR = $ENV{'TMPDIR'} // "/tmp";
my $filesCache = "${TMPDIR}/nixos-files.sqlite";
my $bucketReleasesName = "nix-releases";
my $bucketChannelsName = "nix-channels";
my $dryRun = $ENV{'DRY_RUN'} // 0;

$ENV{'GIT_DIR'} = "/home/hydra-mirror/nixpkgs-channels";

my $bucketReleases;
my $bucketChannels;

unless ($dryRun) {
    # S3 setup.
    my $aws_access_key_id = $ENV{'AWS_ACCESS_KEY_ID'} or die "No AWS_ACCESS_KEY_ID given.";
    my $aws_secret_access_key = $ENV{'AWS_SECRET_ACCESS_KEY'} or die "No AWS_SECRET_ACCESS_KEY given.";

    my $s3 = Net::Amazon::S3->new(
        { aws_access_key_id     => $aws_access_key_id,
          aws_secret_access_key => $aws_secret_access_key,
          retry                 => 1,
          host                  => "s3-eu-west-1.amazonaws.com",
        });

    $bucketReleases = $s3->bucket($bucketReleasesName) or die;

    my $s3_us = Net::Amazon::S3->new(
        { aws_access_key_id     => $aws_access_key_id,
          aws_secret_access_key => $aws_secret_access_key,
          retry                 => 1,
        });

    $bucketChannels = $s3_us->bucket($bucketChannelsName) or die;
} else {
    print STDERR "WARNING: Running in dry-run.\n";
}

sub fetch {
    my ($url, $type) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->default_header('Accept', $type) if defined $type;

    my $response = $ua->get($url);
    die "could not download $url: ", $response->status_line, "\n" unless $response->is_success;

    return $response->decoded_content;
}

my $releaseInfo = decode_json(fetch($releaseUrl, 'application/json'));

my $releaseId = $releaseInfo->{id} or die;
my $releaseName = $releaseInfo->{nixname} or die;
$releaseName =~ /-([0-9].+)/ or die;
my $releaseVersion = $1;
my $evalId = $releaseInfo->{jobsetevals}->[0] or die;
my $evalUrl = "https://hydra.nixos.org/eval/$evalId";
my $evalInfo = decode_json(fetch($evalUrl, 'application/json'));
my $releasePrefix = "$channelDirRel/$releaseName";

my $rev = $evalInfo->{jobsetevalinputs}->{nixpkgs}->{revision} or die;

# Get commit date of $rev as unixtime and formatted string
run("git fetch origin $rev >&2");
my $revUnix = `git show --no-patch --format='%ct' $rev` or die;
my $revDate = strftime("%F %T %Z", localtime($revUnix));

print STDERR "\nRelease information:\n";
print STDERR " - release is: $releaseName (build $releaseId)\n - eval is: $evalId\n - prefix is: $releasePrefix\n - Git commit is: $rev\n - Git commit date is: $revDate\n\n";

if ($bucketChannels) {
    # Guard against the channel going back in time.
    my $curRelease = "";

    if (defined(my $object = $bucketChannels->get_key($channelName))) {
        $curRelease = $object->{'x-amz-website-redirect-location'} // "";
    }

    if (!defined $ENV{'FORCE'}) {
        print STDERR "previous release is $curRelease\n";
        $! = 0; # Clear errno to avoid reporting non-fork/exec-related issues
        my $d = `NIX_PATH= nix-instantiate --eval -E "builtins.compareVersions (builtins.parseDrvName \\"$curRelease\\").version (builtins.parseDrvName \\"$releaseName\\").version"`;
        if ($? != 0) {
            warn "Could not execute nix-instantiate: exit $?; errno $!\n";
            exit 1;
        }
        chomp $d;
        if ($d == 1) {
            warn("channel would go back in time from $curRelease to $releaseName, bailing out\n");
            exit;
        }
        exit if $d == 0;
    }
}

if ($bucketReleases && $bucketReleases->head_key("$releasePrefix")) {
    print STDERR "release already exists\n";
} else {
    my $tmpDir = "$TMPDIR/release-$channelName/$releaseName";
    File::Path::make_path($tmpDir);

    write_file("$tmpDir/src-url", $evalUrl);
    write_file("$tmpDir/git-revision", $rev);
    write_file("$tmpDir/binary-cache-url", "https://cache.nixos.org");

    if (! -e "$tmpDir/store-paths.xz") {
        my $storePaths = decode_json(fetch("$evalUrl/store-paths", 'application/json'));
        write_file("$tmpDir/store-paths", join("\n", uniq(@{$storePaths})) . "\n");
    }

    sub downloadFile {
        my ($jobName, $dstName, $productType) = @_;

        my $buildInfo = decode_json(fetch("$evalUrl/job/$jobName", 'application/json'));

        my $products = ();
        # Key the products by subtype.
        foreach my $key (keys $buildInfo->{buildproducts}->%*) {
            my $subType = $buildInfo->{buildproducts}->{$key}->{subtype};
            if ($products->{$subType}) {
                die "Job $jobName has multiple products of the same subtype $subType.\nThis is a bad assumption from this script";
            }
            $products->{$subType} = $buildInfo->{buildproducts}->{$key};
        }
        my $size = keys %{$products};

        if ($size > 1 && !$productType) {
            my $types = join(", ", keys %{$products});
            die "Job $jobName has $size build products. Select the right product by subtype [$types]";
        }

        my $product;
        if (!$productType) {
            # Take the only element
            my ($key) = keys %{$products};
            $product = $products->{$key};
        } else {
            # Take the selected element
            $product = $products->{$productType};
        }

        unless ($product) {
            die "No product could be selected for $jobName, with type $productType";
        }

        my $srcFile = $product->{path} or die "job '$jobName' lacks a store path";
        $dstName //= basename($srcFile);
        my $dstFile = "$tmpDir/" . $dstName;

        my $sha256_expected = $product->{sha256hash} or die;

        if (! -e $dstFile) {
            print STDERR "downloading $srcFile to $dstFile...\n";
            write_file("$dstFile.sha256", "$sha256_expected  $dstName");
            runAllowFailure("NIX_REMOTE=s3://nix-cache nix --experimental-features nix-command store cat '$srcFile' > '$dstFile.tmp'") == 0
                or die "unable to fetch $srcFile\n";
            rename("$dstFile.tmp", $dstFile) or die;
        }

        if (-e "$dstFile.sha256") {
            my $sha256_actual = `nix --experimental-features nix-command hash file --base16 --type sha256 '$dstFile'`;
            chomp $sha256_actual;
            if ($sha256_expected ne $sha256_actual) {
                print STDERR "file $dstFile is corrupt $sha256_expected $sha256_actual\n";
                exit 1;
            }
        }
    }

    if ($channelName =~ /nixos/) {
        downloadFile("nixos.channel", "nixexprs.tar.xz");
        downloadFile("nixpkgs.tarball", "packages.json.br", "json-br");
        downloadFile("nixos.options", "options.json.br", "json-br");

        # Minimal installer ISOs were dropped from the small channel
        if ($channelName !~ /-small/ ||
            $channelName =~ /nixos-2([0123]\...|4\.05)-small/) {
            downloadFile("nixos.iso_minimal.aarch64-linux");
            downloadFile("nixos.iso_minimal.x86_64-linux");
        }

        # All of these jobs are not present in small channels
        if ($channelName !~ /-small/) {
            # These jobs were combined into a single job
            if ($channelName =~ /nixos-2[01234]/) {
                if ($channelName =~ /nixos-2[0123]/) {
                    downloadFile("nixos.iso_plasma5.aarch64-linux");
                    downloadFile("nixos.iso_plasma5.x86_64-linux");
                } else {
                    downloadFile("nixos.iso_plasma6.aarch64-linux");
                    downloadFile("nixos.iso_plasma6.x86_64-linux");
                }

                downloadFile("nixos.iso_gnome.aarch64-linux");
                downloadFile("nixos.iso_gnome.x86_64-linux");
            } else {
                downloadFile("nixos.iso_graphical.aarch64-linux");
                downloadFile("nixos.iso_graphical.x86_64-linux");
            }

            if ($channelName =~ /nixos-2[0123]/) { # i686 dropped for > 23.11
                downloadFile("nixos.iso_minimal.i686-linux");
            }

            if ($channelName =~ /nixos-2([0123]\...|4\.05)/) {
                downloadFile("nixos.ova.x86_64-linux");
            }
        }

    } else {
        downloadFile("tarball", "nixexprs.tar.xz", "source-dist");
        downloadFile("tarball", "packages.json.br", "json-br");
    }

    # Generate the programs.sqlite database and put it in
    # nixexprs.tar.xz. Also maintain the debug info repository at
    # https://cache.nixos.org/debuginfo.
    if ($channelName =~ /nixos/ && -e "$tmpDir/store-paths") {
        File::Path::make_path("$tmpDir/unpack");
        run("tar", "xfJ", "$tmpDir/nixexprs.tar.xz", "-C", "$tmpDir/unpack");
        my $exprDir = glob("$tmpDir/unpack/*");
        run("nix-channel-index", "-o", "$exprDir/programs.sqlite", "-d", "$exprDir/debug.sqlite", "-f", "$exprDir/nixpkgs", "-s", "aarch64-linux", "-s", "x86_64-linux");
        run("index-debuginfo", "$exprDir/debug.sqlite", "s3://nix-cache");
        run("rm", "-f", "$tmpDir/nixexprs.tar.xz", "$exprDir/debug.sqlite");
        unlink("$tmpDir/nixexprs.tar.xz.sha256");
        run("tar", "cfJ", "$tmpDir/nixexprs.tar.xz", "-C", "$tmpDir/unpack", basename($exprDir));
        run("rm", "-rf", "$tmpDir/unpack");
    }

    if (-e "$tmpDir/store-paths") {
        run("xz", "$tmpDir/store-paths");
    }

    my $now = strftime("%F %T %Z", localtime);
    my $title = "$channelName release $releaseName";
    my $githubLink = "https://github.com/NixOS/nixpkgs/commits/$rev";

    my $html = "<html><head>";
    $html .= "<title>$title</title></head>";
    $html .= "<body><h1>$title</h1>";
    $html .= "<p>Released on $now from <a href='$githubLink'>Git commit <tt>$rev</tt></a> from $revDate ";
    $html .= "via <a href='$evalUrl'>Hydra evaluation $evalId</a>.</p>";
    $html .= "<table><thead><tr><th>File name</th><th>Size</th><th>SHA-256 hash</th></tr></thead><tbody>";

    if ($bucketReleases) {
        # Upload the release to S3.
        for my $fn (sort glob("$tmpDir/*")) {
            my $basename = basename $fn;
            my $key = "$releasePrefix/" . $basename;

            unless (defined $bucketReleases->head_key($key)) {
                print STDERR "mirroring $fn to s3://$bucketReleasesName/$key...\n";

                # Default headers
                my $configuration = ();
                $configuration->{content_type} = "application/octet-stream";

                if ($fn =~ /.sha256|src-url|binary-cache-url|git-revision/) {
                    # Text files
                    $configuration->{content_type} = "text/plain";
                } elsif ($fn =~ /.json.br$/) {
                    # JSON encoded as brotli
                    $configuration->{content_type} = "application/json";
                    $configuration->{content_encoding} = "br";
                }

                $bucketReleases->add_key_filename(
                    $key, $fn, $configuration
                ) or die $bucketReleases->err . ": " . $bucketReleases->errstr;
            }

            next if $basename =~ /.sha256$/;

            my $size = stat($fn)->size;
            my $sha256 = Digest::SHA::sha256_hex(read_file($fn));
            $html .= "<tr>";
            $html .= "<td><a href='/$key'>$basename</a></td>";
            $html .= "<td align='right'>$size</td>";
            $html .= "<td><tt>$sha256</tt></td>";
            $html .= "</tr>";
        }

        $html .= "</tbody></table></body></html>";

        $bucketReleases->add_key($releasePrefix, $html,
                         { content_type => "text/html" })
            or die $bucketReleases->err . ": " . $bucketReleases->errstr;
    }

    File::Path::remove_tree($tmpDir);
}

if ($dryRun) {
    print STDERR "WARNING: dry-run finished...\n";
    exit(0);
}

# Update the nixos-* branch in the nixpkgs repo.
run("git remote update origin >&2");
run("git push origin $rev:refs/heads/$channelName >&2");

# maxage=600: Serve from cache for 5 minutes.
# stale-while-revaliadate=1800: Serve from cache while updating in the background for 30 minutes.
# https://web.dev/stale-while-revalidate/
# https://developer.fastly.com/learning/concepts/cache-freshness/
my $cache_control = "maxage=600,stale-while-revalidate=1800,public";

sub redirect {
    my ($from, $to) = @_;
    $to = "https://releases.nixos.org/" . $to;
    print STDERR "redirect $from -> $to\n";
    $bucketChannels->add_key($from, "", { "x-amz-website-redirect-location" => $to, "cache-control" => $cache_control })
        or die $bucketChannels->err . ": " . $bucketChannels->errstr;
}

# Update channels on channels.nixos.org.
redirect($channelName, $releasePrefix);
redirect("$channelName/nixexprs.tar.xz", "$releasePrefix/nixexprs.tar.xz?rev=$rev&lastModified=$revUnix");
redirect("$channelName/git-revision", "$releasePrefix/git-revision");
redirect("$channelName/packages.json.br", "$releasePrefix/packages.json.br");
redirect("$channelName/store-paths.xz", "$releasePrefix/store-paths.xz");

# Create redirects relevant only to NixOS channels.
# FIXME: create only redirects to files that exist.
if ($channelName =~ /nixos/) {
    # Options listing
    redirect("$channelName/options.json.br", "$releasePrefix/options.json.br");

    # Redirects for latest images.
    for my $arch ("x86_64-linux", "i686-linux", "aarch64-linux") {
        # i686 dropped for > 23.11
        next if $arch eq "i686-linux" && $channelName !~ /nixos-2[0123]/;

        for my $artifact ("nixos-graphical",
                          "nixos-plasma5",
                          "nixos-plasma6",
                          "nixos-gnome",
                          "nixos-minimal",
            )
        {
            redirect("$channelName/latest-$artifact-$arch.iso", "$releasePrefix/$artifact-$releaseVersion-$arch.iso");
            redirect("$channelName/latest-$artifact-$arch.iso.sha256", "$releasePrefix/$artifact-$releaseVersion-$arch.iso.sha256");
        }

        redirect("$channelName/latest-nixos-$arch.ova", "$releasePrefix/nixos-$releaseVersion-$arch.ova");
        redirect("$channelName/latest-nixos-$arch.ova.sha256", "$releasePrefix/nixos-$releaseVersion-$arch.ova.sha256");
    }
}

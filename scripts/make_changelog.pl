#!/usr/bin/env perl

use strict;
use warnings;
use JSON;
use Time::Local;
use Text::CSV;

my $range = $ARGV[0];
our $workdir = './openwrt-changelog-data';

unless (defined $range) {
	printf STDERR "Usage: $0 range\n";
	exit 1;
}

unless (-d $workdir) {
	unless (system('mkdir', '-p', $workdir) == 0) {
		printf STDERR "Unable to create work directory!\n";
		exit 1;
	}
}

my %topics;

sub format_stat($)
{
	my ($commit) = @_;

	my $s = '';
	my $c = '<color #ccc>%s</color>';
	my $g = '<color #282>%s</color>';
	my $r = '<color #f00>%s</color>';

	if ($commit->added > 1000)
	{
		$s .= sprintf $g, sprintf '+%.1fK', $commit->added / 1000;
	}
	elsif ($commit->added > 0)
	{
		$s .= sprintf $g, sprintf '+%d', $commit->added;
	}

	if ($commit->deleted > 1000)
	{
		$s .= $s ? sprintf($c, ',') : '';
		$s .= sprintf $r, sprintf '-%.1fK', $commit->deleted / 1000;
	}
	elsif ($commit->deleted > 0)
	{
		$s .= $s ? sprintf($c, ',') : '';
		$s .= sprintf $r, sprintf '-%d', $commit->deleted;
	}

	return sprintf($c, '(') . $s . sprintf($c, ')');
}

sub format_subject($$)
{
	my ($subject, $body) = @_;

	if (length($subject) > 80)
	{
		$subject = substr($subject, 0, 77) . '...';
	}

	$subject =~ s!^([^\s:]+):\s*!</nowiki>**<nowiki>$1:</nowiki>** <nowiki>!g;

	$subject = sprintf '<nowiki>%s</nowiki>', $subject;
	$subject =~ s!<nowiki></nowiki>!!g;

	return $subject;
}

sub format_change($)
{
	my ($change) = @_;

	printf "''[[%s|%s]]'' %s //%s//\\\\\n",
		sprintf($change->repository->commit_link_template, $change->sha1),
		substr($change->sha1, 0, 7),
		format_subject($change->subject, $change->body),
		format_stat($change);

	my @subhistory = $change->subhistory;

	if (@subhistory > 0) {
		my $n = 0;
		my $link_tpl;

		foreach my $subchange (@subhistory) {
			if ($n == 0) {
				$link_tpl = $subchange->repository->commit_link_template;
			}

			if ($link_tpl) {
				printf " => ''[[%s|%s]]'' %s //%s//\\\\\n",
					sprintf($link_tpl, $subchange->sha1),
					substr($subchange->sha1, 0, 7),
					format_subject($subchange->subject, $subchange->body),
					format_stat($subchange);
			}
			else {
				printf " => ''%s'' %s //%s//\\\\\n",
					substr($subchange->sha1, 0, 7),
					format_subject($subchange->subject, $subchange->body),
					format_stat($subchange);
			}

			if (++$n > 15 && @subhistory > $n) {
				printf " => + //%u more...//\\\\\n", @subhistory - $n;
				last;
			}
		}
	}
}

sub fetch_cve_info()
{
	unless (-f "$workdir/cveinfo.csv")
	{
		system('wget', '-O', "$workdir/cveinfo.csv.gz", 'https://cve.mitre.org/data/downloads/allitems.csv.gz') && return 0;
		system('gunzip', '-f', "$workdir/cveinfo.csv.gz") && return 0;
	}

	return 1;
}

sub parse_cves(@)
{
	my $csv = Text::CSV->new({ binary => 1 });
	my %cves;

	if (fetch_cve_info() && $csv)
	{
		if (open CVE, '<', "$workdir/cveinfo.csv")
		{
			while (defined(my $row = $csv->getline(*CVE)))
			{
				foreach my $cve_id (@_)
				{
					if ($row->[0] eq $cve_id)
					{
						$cves{$cve_id} = [$row->[2], $row->[6]];
						last;
					}
				}
			}

			close CVE;
		}
	}

	return \%cves;
}


my $repository = Repository->new('https://git.openwrt.org/openwrt/openwrt.git');
my $bugtracker = BugTracker->new;

my @commits = $repository->parse_history($range);
my (%bugs, %cves, %sha1s);

foreach my $commit (@commits)
{
	if ($commit->subject =~ m!\b(?:LEDE|OpenWrt) v\d\d\.\d\d\.\d+(?:-rc\d+)?: (?:adjust config|revert to branch) defaults\b!) {
		Log::info("Skipping maintenance commit %s (%s)", $commit->sha1, $commit->subject);
		next;
	}

	my @topics = $commit->topics;

	foreach my $topic (@topics)
	{
		$topics{$topic} ||= [ ];
		push @{$topics{$topic}}, $commit;
	}

	foreach my $bug ($commit->bugs) {
		if ($bug->status ne 'closed') {
			Log::warn("Commit %s closes bug #%d", $commit->sha1, $bug->id);
		}

		$bugs{ $bug->id } ||= [ ];
		push @{$bugs{ $bug->id }}, $commit;
	}

	foreach my $cve_id ($commit->cve_ids) {
		$cves{$cve_id} ||= [ ];
		push @{$cves{$cve_id}}, $commit;
	}

	$sha1s{$commit->[1]}++;
}

Log::info("Finding commit references in bugs...");

foreach my $bug ($bugtracker->bugs)
{
	next if exists $bugs{ $bug->id };

	foreach my $hash ($bug->refs) {
		my $commit = $repository->find_commit($hash);
		next unless defined $commit;

		if ($bug->status ne 'closed') {
			Log::warn("Bug #%d closed by commit %s", $bug->id, $commit->sha1);
		}

		$bugs{ $bug->id } ||= [ ];
		push @{$bugs{ $bug->id }}, $commit;
	}
}


my @topics = sort { (($a eq 'Miscellaneous') <=> ($b eq 'Miscellaneous')) || $a cmp $b } keys %topics;

foreach my $topic (@topics)
{
	my @commits = @{$topics{$topic}};

	printf "==== %s (%d change%s) ====\n", $topic, 0 + @commits, @commits > 1 ? 's' : '';

	foreach my $change (sort { $a->pos <=> $b->pos } @commits)
	{
		format_change($change);
	}

	print "\n";
}

my @bugs = map { $bugtracker->get($_) } sort { int($a) <=> int($b) } keys %bugs;

if (@bugs > 0) {
	printf "===== Addressed bugs =====\n";

	foreach my $bug (@bugs)
	{
		if ($bug->fsid) {
			printf "=== FS#%d (#%d) ===\n", $bug->fsid, $bug->id;
		}
		else {
			printf "=== #%d ===\n", $bug->id;
		}

		printf "**Description:** <nowiki>%s</nowiki>\\\\\n", $bug->summary;
		printf "**Link:** [[https://github.com/openwrt/openwrt/issues/%d]]\\\\\n", $bug->id;
		printf "**Commits:**\\\\\n";

		foreach my $commit (@{$bugs{ $bug->id }})
		{
			format_change($commit);
		}

		printf "\\\\\n";
	}

	printf "\n";
}

my @cves =
	map { $_->[1] }
	sort { ($a->[0] <=> $b->[0]) || ($a->[1] cmp $b->[1]) }
	map { $_ =~ m!^CVE-(\d+)-(\d+)$! ? [ $1 * 10000000 + $2, $_ ] : [ 0, $_ ] }
	keys %cves;

my $cve_info = parse_cves(@cves);

if (@cves > 0)
{
	printf "===== Security fixes ====\n";

	foreach my $cve (@cves)
	{
		printf "=== %s ===\n", $cve;

		if ($cve_info->{$cve} && $cve_info->{$cve}[0])
		{
			printf "**Description:** <nowiki>%s</nowiki>\n\n", $cve_info->{$cve}[0];
		}

		printf "**Link:** [[https://cve.mitre.org/cgi-bin/cvename.cgi?name=%s]]\\\\\n", $cve;
		printf "**Commits:**\\\\\n";

		foreach my $commit (@{$cves{$cve}})
		{
			format_change($commit);
		}

		printf "\\\\\n";
	}

	printf "\n";
}


package Log;

sub info {
	my ($fmt, @args) = @_;
	printf STDERR "[I] %s\n", sprintf $fmt, @args;
	return 0;
}

sub warn {
	my ($fmt, @args) = @_;
	printf STDERR "[W] %s\n", sprintf $fmt, @args;
	return 1;
}

sub err {
	my ($fmt, @args) = @_;
	printf STDERR "[E] %s\n", sprintf $fmt, @args;
	return 1;
}


package GitHubQuery;

sub _date {
	my ($self, $ts) = @_;
	my @loc = gmtime $ts;
	return sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ',
		$loc[5] + 1900, $loc[4] + 1, $loc[3],
		$loc[2], $loc[1], $loc[0];
}

sub _ts {
	my ($self, $date) = @_;
	return 0 unless $date;

	my ($year, $mon, $mday, $hour, $min, $sec) = $date =~ m!^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$!;
	return Time::Local::timegm_posix($sec, $min, $hour, $mday, $mon - 1, $year - 1900);
}

sub _read_cache {
	my ($self, $path, $records) = @_;

	if (open my $file, '<:utf8', $path) {
		local $/;

		eval {
			push @$records, @{ JSON::decode_json(readline $file) };
		};

		close $file;

		if ($@) {
			return Log::err("Unable to read $path: $@");
		}
	}

	return 0;
}

sub _fetch_one_page {
	my ($self, $since, $page) = @_;
	my $url = $self->{'url'};
	my $sep = ($url =~ m!\?!) ? '&' : '?';
	my $res;

	if ($since) {
		$url .= $sep . 'since=' . $self->_date($since);
		$sep = '&';
	}

	if ($page) {
		$url .= $sep . 'per_page=100&page=' . $page;
		$sep = '&';
	}

	if (open my $wget, '-|', 'wget', '--auth-no-challenge', '-q', '-O', '-', $url) {
		local $/;

		eval {
			$res = JSON::decode_json(readline $wget);
		};

		if ($@) {
			Log::err("Failed to parse result from $url: $@");
		}

		close $wget;
	}
	else {
		Log::err("Failed to fetch $url via wget: $!");
	}

	return $res;
}

sub _fetch {
	my ($self) = @_;

	my $cache = "$main::workdir/" . $self->{'cachefile'};
	my @stat = stat $cache;
	my $since = defined($stat[9]) ? $stat[9] : $self->{'since'}; $since -= ($since % 86400);
	my @new_records;
	my @old_records;
	my $page = 1;

	Log::info("Updating " . $self->{'cachefile'} . " database...");

	while (1) {
		my $res = $self->_fetch_one_page($since, $page);

		if (ref($res) ne 'ARRAY') {
			return Log::err("Aborting update due to invalid response");
		}

		push @new_records, @$res;

		Log::info("  Fetched " . @new_records . " records...");

		last if @$res < 100;

		$page++;
	}

	if ($self->_read_cache($cache, \@old_records)) {
		return 1;
	}

	my $updated = 0;
	my %index;

	foreach my $record (@old_records) {
		if (ref($record) ne 'HASH' || !exists($record->{ $self->{'idprop'} })) {
			next;
		}

		$index{ $record->{ $self->{'idprop'} } } = $record;
	}

	foreach my $record (@new_records) {
		if (ref($record) ne 'HASH' || !exists($record->{ $self->{'idprop'} })) {
			next;
		}

		my $old = $index{ $record->{ $self->{'idprop'} } };

		if (!$old || $self->_ts($record->{'updated_at'}) != $self->_ts($old->{'updated_at'})) {
			$index{ $record->{ $self->{'idprop'} } } = $record;
			$updated++;
		}
	}

	if (!defined($stat[9]) || $updated) {
		Log::info("  Found " . $updated . " updated records...");

		if (open my $file, '>:utf8', $cache) {
			print $file JSON::encode_json([ values %index ]);
			close $file;
		}
		else {
			return Log::err("Unable to update $cache: $!");
		}

		my $now = time();

		if (!utime($now, $now, $cache)) {
			Log::warn("Unable to change $cache modification time: $!");
		}
	}

	return 0;
}

sub fetch {
	my ($self, $force_update) = @_;
	my $cache = "$main::workdir/" . $self->{'cachefile'};
	my @records;

	if ($force_update) {
		$self->_fetch();
	}

	if (-f $cache && $self->_read_cache($cache, \@records)) {
		return undef;
	}

	return wantarray ? @records : \@records;
}

sub new {
	my ($pack, $baseurl, $cachefile, $idprop, $since) = @_;

	return bless {
		url       => $baseurl,
		cachefile => $cachefile,
		idprop    => $idprop,
		since     => $since
	}, $pack;
}


package BugTracker;

our $inst;

sub _parse {
	my ($self) = @_;

	return 0 if $self->{'bugs'};

	my $issues = GitHubQuery->new(
		"https://api.github.com/repos/openwrt/openwrt/issues?state=all&sort=updated&direction=desc",
		"issues.json",
		"number",
		1640995200
	)->fetch(1);

	return 1 unless $issues;

	$self->{'bugs'} = { };
	$self->{'fsbugs'} = { };

	foreach my $issue (@$issues) {
		my ($date_opened, $date_closed, $date_modified) = (0, 0, 0);

		if (exists($issue->{'created_at'})) {
			$date_opened = GitHubQuery->_ts($issue->{'created_at'});
		}

		if (exists($issue->{'updated_at'})) {
			$date_modified = GitHubQuery->_ts($issue->{'updated_at'});
		}

		if (exists($issue->{'closed_at'})) {
			$date_closed = GitHubQuery->_ts($issue->{'closed_at'});
		}

		my $bug = Bug->new(
			$issue->{'number'},
			$issue->{'title'},
			$issue->{'state'},
			$date_opened,
			$date_closed,
			$date_modified
		);

		$self->{'bugs'}{ $bug->id } = $bug;

		if ($issue->{'title'} =~ /^FS#(\d+) - /) {
			$self->{'fsbugs'}{$1} = $bug;
		}
	}

	return 0;
}

sub new {
	my ($pack) = @_;

	unless ($inst) {
		$inst = bless {}, $pack;
	}

	return $inst;
}

sub get($$) {
	my ($self, $id) = @_;

	return undef if $self->_parse;
	return $self->{'bugs'}{$id};
}

sub get_fs($$) {
	my ($self, $id) = @_;

	return undef if $self->_parse;
	return $self->{'fsbugs'}{$id};
}

sub bugs($) {
	my ($self) = @_;
	return undef if $self->_parse;

	my @bugs = map { $self->{'bugs'}{$_} } sort { $a <=> $b } keys %{$self->{'bugs'}};
	return wantarray ? @bugs : \@bugs;
}


package Bug;

use File::Basename;
use constant {
	'_ID'     => 0,
	'_SUM'    => 1,
	'_STAT'   => 2,
	'_OPEN'   => 3,
	'_CLOSE'  => 4,
	'_CHANGE' => 5,
	'_FSID'   => 6,
	'_REFS'   => 7
};

sub new
{
	my ($pack, $id, $summary, $status, $opened, $closed, $modified) = @_;
	my $fsid = undef;

	if ($summary =~ s/^FS#(\d+) - //) {
		$fsid = $1;
	}

	return bless [
		$id,
		$summary,
		$status,
		$opened,
		$closed,
		$modified,
		$fsid
	], $pack;
}

sub id { shift->[_ID] }
sub fsid { shift->[_FSID] }
sub url { sprintf 'https://api.github.com/repos/openwrt/openwrt/issues/%d/comments', shift->id }
sub file { sprintf '%s/issue/%d.json', $main::workdir, shift->id }
sub summary { shift->[_SUM] }
sub status { shift->[_STAT] }

sub _fetch()
{
	my ($self) = @_;
	my @stat = stat $self->file;
	my $refresh = 0;

	if (!defined($stat[9]) || ($stat[9] < $self->[_CHANGE])) {
		$refresh = 1;
	}

	#Log::info("Fetching details for Bug #%d ...", $self->id);

	if (system('mkdir', '-p', "$main::workdir/issue")) {
		return Log::err("Unable to create directory!");
	}

	my $comments = GitHubQuery->new(
		$self->url,
		sprintf('issue/%d.json', $self->id),
		'id',
		0
	)->fetch($refresh);

	if (!$comments) {
		Log::err("Unable to fetch bug details!");

		return undef;
	}

	return wantarray ? @$comments : $comments;
}

sub _find_commit_references()
{
	my ($self) = @_;
	my $comments = $self->_fetch;

	return undef unless $comments;

	foreach my $comment (@$comments) {
		my $str = $comment->{'body'};
		my @refs = $str =~ m!
			(?:
				Fixed \s+ with \s+ |
				Fixed \s+ in \s+ |
				Fixed \s+ by \s+ |
				fix \s+ (?: in | into ) \s+ (?: \w+ \s+ )*
			)
			(?: <a \s+ href=" )?  # "
			\b (
				https?://git\.(?:openwrt|lede-project)\.org/\?p=[\w/]+\.git\S*;h=[a-fA-F0-9]{4,40} |
				https?://git\.(?:openwrt|lede-project)\.org/[a-fA-F0-9]{4,40} |
				https?://github\.com/[^/]+/commit/[a-fA-F0-9]{4,40} |
				[a-fA-F0-9]{7,40}
			) \b
		!ixg;

		return @refs if @refs > 0;
	}
}

sub refs ($) {
	my ($self) = @_;

	unless (defined $self->[_REFS]) {
		my %sha1;

		foreach my $ref ($self->_find_commit_references) {
			if ($ref =~ m!\b([a-fA-F0-9]{4,40})$!) {
				$sha1{lc $1}++;
			}
		}

		$self->[_REFS] = [ sort keys %sha1 ];
	}

	return wantarray ? @{$self->[_REFS]} : $self->[_REFS];
}


package Repository;

use File::Basename;

our %repositories;
our %commits;
our @index;

sub new($$) {
	my ($pack, $url) = @_;

	my $id = $url;
	   $id =~ s!\bgit\.lede-project\.org\b!git.openwrt.org!;
	   $id =~ s![^a-z0-9_-]+!-!g;

	unless (exists $repositories{$id}) {
		$repositories{$id} = bless {
			'id' => $id,
			'url' => $url,
			'cache' => { }
		}, $pack;

		$repositories{$id}->_fetch;
	}

	return $repositories{$id};
}

sub id { shift->{'id'} }
sub url { shift->{'url'} }
sub directory { sprintf '%s/repos/%s', $main::workdir, shift->id }

sub _fetch($) {
	my ($self) = @_;

	if (-d $self->directory) {
		Log::info("Updating repository %s ...", $self->url);

		my $tree = $self->directory;
		my $git  = $tree . '/.git';

		if (system('git', "--work-tree=$tree", "--git-dir=$git", 'fetch', '--all', '--quiet')) {
			return Log::err("Unable to pull repository!");
		}

		return 0;
	}

	Log::info("Cloning repository %s ...", $self->url);

	if (system('mkdir', '-p', $self->directory)) {
		return Log::err("Unable to create directory!");
	}
	elsif (system('git', 'clone', '--quiet', $self->url, $self->directory)) {
		return Log::err("Unable to clone repository!");
	}

	return 0;
}

sub _readline($*$) {
	my ($self, $fh, $default) = @_;

	my $line = readline $fh;

	if (defined $line)
	{
		chomp $line;
		return $line;
	}

	return $default;
}

sub _parse($*)
{
	my ($self, $fh) = @_;
	my @commits;
	my $num = 0;

	# skip header line
	$self->_readline($fh, undef);

	while (1) {
		my $hash = $self->_readline($fh, '');
		my $subject = $self->_readline($fh, '');

		last unless (length($subject) && $hash =~ m!^[a-f0-9]{40}$!);

		my $line = '';

		# commit already cached, skip lines and use cached object
		if (exists $Repository::commits{$hash}) {
			for ($line = ''; $line ne '@@'; $line = $self->_readline($fh, '@@')) { next; }
			for ($line = ''; $line ne '@@'; $line = $self->_readline($fh, '@@')) { next; }

			push @commits, $Repository::commits{$hash};
			next;
		}

		my $body = '';
		my @files;
		my ($add, $del) = (0, 0);

		while ($line ne '@@') {
			$body .= length($line) ? "$line\n" : '';
			$line = $self->_readline($fh, '@@');
		}

		$line = '';

		my $reading_diff = 0;
		my ($subhistory, $subhistory_url, $subhistory_start, $subhistory_end);

		while ($line ne '@@') {
			if ($line =~ m!^diff --git a/!) {
				$reading_diff = 1;
				undef $subhistory_url;
				undef $subhistory_start;
				undef $subhistory_end;
			}
			elsif ($reading_diff) {
				if ($line =~ m!^[ +]PKG_SOURCE_URL\s*:?=\s*(\S+)!) {
					$subhistory_url = $1;
					$subhistory_url =~ s!\$\(LEDE_GIT\)!https://git.lede-project.org!g;
					$subhistory_url =~ s!\$\(OPENWRT_GIT\)!https://git.openwrt.org!g;
					$subhistory_url =~ s!\$\(PROJECT_GIT\)!https://git.openwrt.org!g;
				}
				elsif ($line =~ m!^-\S+\s*:?=\s*([a-f0-9]{40})\b!) {
					$subhistory_start = $1;
				}
				elsif ($line =~ m!^\+\S+\s*:?=\s*([a-f0-9]{40})\b!) {
					$subhistory_end = $1;

					if ($subhistory_url && $subhistory_start && $subhistory_end) {
						$subhistory = Repository->new($subhistory_url)->parse_history("$subhistory_start..$subhistory_end");
					}
				}
			}
			elsif ($line =~ m!^(\d+|-)\s+(\d+|-)\s+(.+)$!) {
				$add += ($1 eq '-') ? 0 : int($1);
				$del += ($2 eq '-') ? 0 : int($2);
				push @files, $3;
			}

			$line = $self->_readline($fh, '@@');
		}

		my $commit = Commit->new($self, $num++, $hash, $subject, $body, $add, $del, $subhistory, @files);

		push @commits, $commit;
		push @Repository::index, $commit;

		$Repository::commits{ $commit->sha1 } = $commit;
	}

	@Repository::index = sort { $a->sha1 cmp $b->sha1 } @Repository::index;

	return wantarray ? @commits : \@commits;
}

sub parse_history($$) {
	my ($self, $range) = @_;
	my $gitdir = sprintf '%s/.git', $self->directory;
	my @commits;

	if (open my $git, '-|', 'git', "--git-dir=$gitdir", 'log', '-p', '--format=@@%n%H%n%s%n%b%n@@', '--numstat', '--reverse', '--no-merges', $range) {
		@commits = $self->_parse($git);
		close $git;
	}

	return wantarray ? @commits : \@commits;
}

sub find_commit($$) {
	my ($self, $hash) = @_;

	if (exists $Repository::commits{$hash}) {
		return $Repository::commits{$hash};
	}
	else {
		my ($l, $r) = (0, @Repository::index - 1);

		while ($l <= $r) {
			my $m = $l + int(($r - $l) / 2);

			if (index($Repository::index[$m]->sha1, $hash) == 0) {
				return $Repository::index[$m];
			}
			elsif ($Repository::index[$m]->sha1 gt $hash) {
				$r = $m - 1;
			}
			else {
				$l = $m + 1;
			}
		}
	}

	return undef;
}

sub _weblinks { (
	[ qr'^[^:]+://(git.lede-project.org/)(.+)$' => 'https://%s?p=%s;a=commitdiff;h=%%s' ],
	[ qr'^[^:]+://(git.openwrt.org/)(.+)$'      => 'https://%s?p=%s;a=commitdiff;h=%%s' ],
	[ qr'^[^:]+://(github.com/.+?)(?:\.git)?$'  => 'https://%s/commit/%%s' ],
	[ qr'^[^:]+://git.kernel.org/pub/scm/(.+)$' => 'https://git.kernel.org/cgit/%s/commit/?id=%%s' ],
	[ qr'^[^:]+://w1.fi/(?:.+/)?(.+)\.git$'     => 'https://w1.fi/cgit/%s/commit/?id=%%s' ],
	[ qr'^[^:]+://git.netfilter.org/(.+)'       => 'https://git.netfilter.org/%s/commit/?id=%%s' ],
	[ qr'^[^:]+://git.musl-libc.org/(.+)'       => 'https://git.musl-libc.org/cgit/%s/commit/?id=%%s' ],
	[ qr'^[^:]+://git.zx2c4.com/(.+)'           => 'https://git.zx2c4.com/%s/commit/?id=%%s' ],
	[ qr'^[^:]+://sourceware.org/git/(.+)'      => 'https://sourceware.org/git/?p=%s;a=commitdiff;h=%%s' ]
) }

sub commit_link_template($) {
	my ($self) = @_;

	foreach my $lnk ($self->_weblinks) {
		my @matches = $self->url =~ $lnk->[0];
		if (@matches > 0) {
			return sprintf $lnk->[1], @matches;
		}
	}

	Log::warn("No web link template available for %s", $self->url);
	return undef;
}

sub log($) {
	my ($self) = @_;
	return wantarray ? @{$self->{'log'}} : $self->{'log'};
}


package Commit;

use constant {
	'_REPO'  => 0,
	'_POS'   => 1,
	'_SHA1'  => 2,
	'_SUBJ'  => 3,
	'_BODY'  => 4,
	'_FILES' => 5,
	'_SHIST' => 6,
	'_NADD'  => 7,
	'_NDEL'  => 8
};

sub _topic_map { (
	[ qr'^package/(kernel)/linux',                 'Kernel' ],
	[ qr'^(target/linux/generic|include/kernel-version.mk)', 'Kernel' ],
	[ qr'^package/kernel/(mac80211)',              'Wireless / Common' ],
	[ qr'^package/kernel/(ath10k-ct)',             'Wireless / Ath10k CT' ],
	[ qr'^package/kernel/(mt76)',                  'Wireless / MT76' ],
	[ qr'^package/kernel/(mwlwifi)',               'Wireless / Mwlwifi' ],
	[ qr'^package/(base-files)/',                  'Packages / OpenWrt base files' ],
	[ qr'^package/(boot)/',                        'Packages / Boot Loaders' ],
	[ qr'^package/firmware/',                      'Packages / Firmware' ],
	[ qr'^package/.+/(uhttpd|usbmode|jsonfilter|ugps|libubox|procd|mountd|ubus|uci|usign|rpcd|fstools|ubox)/', 'Packages / OpenWrt system userland' ],
	[ qr'^package/.+/(iwinfo|umbim|uqmi|relayd|mdns|firewall|netifd|uclient|ustream-ssl|gre|ipip|qos-scripts|swconfig|vti|6in4|6rd|6to4|ds-lite|map|odhcp6c|odhcpd)/', 'Packages / OpenWrt network userland' ],
	[ qr'^package/[^/]+/([^/]+)',                  'Packages / Common' ],
	[ qr'^target/sdk/',                            'Build System / SDK' ],
	[ qr'^target/imagebuilder/',                   'Build System / Image Builder' ],
	[ qr'^target/toolchain/',                      'Build System / Toolchain' ],
	[ qr'^target/linux/([^/]+)',                   'Target / $1' ],
	[ qr'^(tools)/[^/]+',                          'Build System / Host Utilities' ],
	[ qr'^(toolchain)/[^/]+',                      'Build System / Toolchain' ],
	[ qr'^(config/|include/|scripts/|target/[^/]+$|Makefile|rules\.mk)', 'Build System / Buildroot' ],
	[ qr'^(feeds)\b',                              'Build System / Feeds' ],
) }

sub new ($$$$$$$$@) {
	my ($pack, $repo, $pos, $hash, $subject, $body, $add, $del, $shist, @files) = @_;
	my @commit;

	$commit[_REPO] = $repo;
	$commit[_POS]  = $pos;
	$commit[_SHA1] = $hash;
	$commit[_SUBJ] = $subject;
	$commit[_BODY] = $body;
	$commit[_NADD] = $add;
	$commit[_NDEL] = $del;
	$commit[_SHIST] = $shist;
	$commit[_FILES] = \@files;

	return bless \@commit, $pack;
}

sub repository { shift->[_REPO] }
sub pos { shift->[_POS] }
sub sha1 { shift->[_SHA1] }
sub subject { shift->[_SUBJ] }
sub body { shift->[_BODY] }
sub added { shift->[_NADD] }
sub deleted { shift->[_NDEL] }
sub files { wantarray ? @{shift->[_FILES] || []} : shift->[_FILES] }
sub subhistory { wantarray ? @{shift->[_SHIST] || []} : shift->[_SHIST] }

sub topics($) {
	my ($self) = @_;
	my %topics;
	my %paths;

	foreach my $path ($self->files)
	{
		if ($path =~ m!^(.+)/\{(.+?) => (.+?)\}$!)
		{
			$paths{"$1/$2"}++;
			$paths{"$1/$3"}++;
		}
		else
		{
			$paths{$path}++;
		}
	}

	foreach my $path (sort keys %paths)
	{
		foreach my $rs ($self->_topic_map)
		{
			if ($path =~ $rs->[0])
			{
				my $m = $1;
				my $s = $rs->[1];

				$s =~ s!\$1!$m!g;
				$topics{$s}++;

				last;
			}
		}
	}

	my @topics = sort keys %topics;
	return (@topics > 0 ? @topics : ('Miscellaneous'));
}

sub bugs($) {
	my ($self) = @_;

	my $bugtracker = BugTracker->new;
	my $candidates = qr'\b((?:[Pp]ull [Rr]equest |[Bb]ug |[Ii]ssue |PR |FS |GH |PR|FS|GH)#\d+)\b';
	my %bugs;

	foreach my $match ($self->subject =~ /$candidates/g, $self->body =~ /$candidates/g) {
		my $bug;

		if ($match =~ /^FS ?#(\d+)$/) {
			$bug = $bugtracker->get_fs($1);
		}
		elsif ($match =~ /^(GH|PR|[Pp]ull [Rr]equest) ?#(\d+)$/i) {
			$bug = $bugtracker->get($1);
		}
		elsif ($match =~ /^#(\d+)$/) {
			$bug = $bugtracker->get_fs($1) || $bugtracker->get($1);
		}

		if ($bug) {
			$bugs{ $bug->id } = $bug;
		}
	}

	foreach my $tag (qw(Fixes Closes Supersedes)) {
		my ($ids) = $self->body =~ /\b$tag: *((?:GH|PR|FS|)#\d+(?:[, ]+#\d+)*)/;

		foreach my $id (split /[, ]+/, ($ids || '')) {
			my $bug;

			if ($id =~ /^FS#(\d+)$/) {
				$bug = $bugtracker->get_fs($1);
			}
			elsif ($id =~ /^(GH|PR)#(\d+)$/) {
				$bug = $bugtracker->get($1);
			}
			elsif ($id =~ /^#(\d+)$/) {
				$bug = $bugtracker->get_fs($1) || $bugtracker->get($1);
			}

			if ($bug) {
				$bugs{ $bug->id } = $bug;
			}
		}
	}

	return map { $bugs{$_} } sort { $a <=> $b } keys %bugs;
}

sub cve_ids($) {
	my ($self) = @_;
	my $candidates = qr'\b(CVE-\d+-\d+|\d+-CVE-\d+)\b';
	my %cves;

	foreach my $match ($self->subject =~ /$candidates/g, $self->body =~ /$candidates/g) {
		# fix misspelled CVE IDs
		$match =~ s!^(\d+)-CVE-!CVE-$1-!;
		$cves{$match}++;
	}

	return sort { $a cmp $b } keys %cves;
}

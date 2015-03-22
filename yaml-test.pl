use strict;
use warnings;
use YAML;
use File::Find;
use Data::Dumper;
use Data::Compare;
use Cwd 'abs_path';

my $master = {};
my @files_dont_exist = ();
my @difs = (); 

my $cmd = shift @ARGV;
backup() if $cmd eq "backup";
compare() if $cmd eq "compare";

sub compare {
	$master = read_yaml(shift @ARGV);
	foreach my $file (keys %$master) {
		if (!-e $file) {
			push(@files_dont_exist, $file);
			next;
		}
		
		my $src_obj = $master->{$file}; 
		my $des_obj = read_yaml($file);

		foreach my $key (keys %$src_obj) {
			my $src_val = $src_obj->{$key};
			my $des_val = $des_obj->{$key};
			if (!Compare($src_val, $des_val)) {
				push(@difs, "$file: $key: $src_val -> $des_val");
			}
		}
	}

	if (@files_dont_exist) {
		print("Files that don't exist\n");
		foreach (@files_dont_exist) {
			print $_, "\n";
		}
	}

	print("Differences found:\n");
	foreach (@difs) {
		print $_, "\n";
	}
}

sub backup {
	find(\&process_file, abs_path(shift @ARGV));
	print(Dump($master), "\n");
}

sub process_file {
	if ($File::Find::name =~ /\.yaml|\.yml/i) {
		$master->{$File::Find::name} = read_yaml($File::Find::name);
	}	
}	

sub read_yaml {
	my $filename = shift;
	open(my $fh, '<', $filename);
	my $text = do { local $/ = undef; <$fh>; };
	my $obj = Load($text);
	return $obj;
}

#
# Creates checksums for a set of files, then reports duplicates.
#
require 'optparse'
require 'digest/md5'

$files = Hash.new
$files_processed = 0

BLOCKSIZE = 8192

# Arbitrary list of directory names not to traverse.
BLACKLIST = [ ".", "..", ".DS_Store", ".svn", ".metadata"]

$options = {}

#
# Recursively descends a directory tree, computing the checksums of all files,
# then storing checksums in a Hash containing an array of names of the 
# duplicate files.
#
def process_dir(dirname)
	Dir.entries(dirname).each { |filename|
		next if BLACKLIST.include? filename
		entry = File.join dirname, filename
		next if File.symlink? entry

		if File.directory? entry then
			process_dir entry
		else
			checksum = checksum entry
			$files[checksum] ||= Array.new 
			$files[checksum] << entry
			printf "%s %s\n", checksum, entry if $options[:verbose]
			$files_processed += 1
		end
	}
end

#
# Computes the MD5 checksum of a file, given its name.
#
def checksum(filename) 
	File.open(filename) { |file|
		digest = Digest::MD5.new
		while buf = file.read(BLOCKSIZE)
			digest.update buf
		end		
		digest.to_s
	}
end

cmd_opts = OptionParser.new do |opts|
	opts.banner = "Usage duplicates.rb [-v] [dirname]"

	$options[:verbose] = false
	opts.on('-v', '--verbose', 'Be verbose. Reports the checksum and name of every file processed.') do
		$options[:verbose] = true
	end

	opts.on( '-h', '--help', 'Display this screen' ) do
    	puts opts
    	exit
   end
end

cmd_opts.parse!

# 
# Use current directory if no directory arguments were given.
#
if ARGV.size == 0 then
	process_dir "." 
else
	ARGV.each do |dir|
		process_dir(dir)
	end
end

puts "#{$files_processed} files processed."
puts "#{$files_processed - $files.size} duplicates found."

# 
# Report all duplicate file names.
#
$files.each_pair { |checksum,filenames|
	if filenames.size > 1 then
		puts "#{checksum}:"
		filenames.each { |name| puts name }
		puts
	end
}

#
# Creates checksums for a set of files, then reports duplicates
#
require 'digest/md5'

$files = Hash.new
$files_processed = 0
BLOCKSIZE = 8192

BLACKLIST = [ ".", "..", ".DS_Store", ".svn", ".metadata"]

#
# Recursively descends a directory tree, computing the checksums of all files,
# then storing duplicate checksums in a Hash.
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
			printf "%s %s\n", checksum, entry if $verbose
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



process_dir(".")

puts "#{$files_processed} files processed."
puts "#{$files_processed - $files.size} duplicates found."

$files.each_pair {|checksum,filenames|
	if filenames.size > 1 then
		puts "#{checksum}:"
		filenames.each {|name|
			puts name
		}
		puts
	end
}

#!/usr/bin/env ruby
require "fusefs"
require "logger"

$LOGGER = Logger.new("/home/alekseiko/mirror_fuse.log", "monthly")
$LOGGER.level = Logger::DEBUG

MIRRORED_DIR = "/"
class MirrorFuse 
    
    def initialize(root)
        @root = root
    end

    def contents(path)
        $LOGGER.debug("Call to give of content by #{path}")
        Dir.entries("#{@root}#{path}") - [".",".."]
    end

    def directory?(path)
        File.directory? "#{@root}#{path}"
    end

    def file?(path)
        File.file? "#{@root}#{path}"
    end

    def read_file(path)
        $LOGGER.debug("Read file by #{path}")
        IO.read("#{@root}#{path}")
    end

    # Write to a file
    def can_write?(path)
        $LOGGER.debug("Can write #{path}")
        File.new("#{@root}#{path}").writable?
    end
    
    def write_to(path, file)
        $LOGGER.debug("Write to path:#{path} file:#{file}")        
    end

    # Delete a file
    def can_delete?(path)
        $LOGGER.debug("Can delete file path : #{path}")
        File.new("#{@root}#{path}").writable? 
    end

    def delete(path)
        $LOGGER.debug("Delete path: #{path}")
        File.delete("#{@root}#{path}")
    end

    # Make a new directory
    def can_mkdir?(path)
        $LOGGER.debug("Can mkdir path : #{path}")
        File.new("#{@root}#{path}").writable?
    end
    
    def mkdir(path, dir = nil)
        $LOGGER.debug("Mkdir path: #{path} dir #{dir}")
        Dir.mkdir("#{@root}#{path}/#{dir}") if dir != nil
    end


    # Delete an existing directory.
    def can_rmdir?(path)
        $LOGGER.debug("Can rmdir path : #{path}")
        File.new("#{@root}#{path}").writable? 
    end

    def rmdir(path)
        $LOGGER.debug("Rmdir path: #{path}")
        Dir.rmdir("#{path}")
    end
end

# init mirror_fuse
mirror_fuse = MirrorFuse.new(MIRRORED_DIR)
FuseFS.set_root(mirror_fuse)

FuseFS.mount_under ARGV.shift
FuseFS.run

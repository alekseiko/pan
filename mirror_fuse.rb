#!/usr/bin/env ruby
require "fusefs"
require "logger"
require "pathname"

$LOGGER = Logger.new(File.join(File.dirname(__FILE__),"mirror_fuse.log"), "monthly")
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
        result = can_write(path)
        $LOGGER.debug("Can write #{path} = #{result}")
        return result
    end

    def write_to(path, data)
        $LOGGER.debug("Write to path:#{path} data:#{data}")
        File.open("#{@root}#{path}", "w+") do |file|
            file.write(data)
        end
    end

    # Delete a file
    def can_delete?(path)
        result = can_write(path)
        $LOGGER.debug("Can delete file path : #{path} = #{result}")
        return result
    end

    def delete(path)
        $LOGGER.debug("Delete path: #{path}")
        File.delete("#{@root}#{path}")
    end

    # Make a new directory
    def can_mkdir?(path)
        result = can_write(path)
        $LOGGER.debug("Can mkdir path : #{path} = #{result}")
        return result
    end

    def mkdir(path, dir = nil)
        $LOGGER.debug("Mkdir path: #{path} dir #{dir}")
        real_path = "#{@root}#{path}"
        real_path += dir unless dir == nil
        Dir.mkdir(real_path) 
    end


    # Delete an existing directory.
    def can_rmdir?(path)
        result = can_write(path)
        $LOGGER.debug("Can rmdir path : #{path} = #{result}")
        return result
    end

    def rmdir(path)
        $LOGGER.debug("Rmdir path: #{path}")
        Dir.rmdir("#{@root}#{path}")
    end
    
    private
    def can_write(path)
        real_path = Pathname.new("#{@root}#{path}")
        File.writable?(real_path.parent)
    end
end
# init mirror_fuse
mirror_fuse = MirrorFuse.new(MIRRORED_DIR)
FuseFS.set_root(mirror_fuse)
FuseFS.mount_under(ARGV.shift,"allow_other")

# Setup trap for TERM signal for unmounting fuse 
# if you sent KILL sign then you need umount fuse by hand
handler = Proc.new {
    $LOGGER.debug("Unmount mirrored fuse")
    FuseFS.unmount
    Process.exit
}
Kernel.trap("TERM", handler)

FuseFS.run

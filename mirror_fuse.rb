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
        @files = {}
    end

    def contents(path)
        $LOGGER.debug("Call to give of content by #{path}")
        Dir.entries(File.join(@root, path)) - [".",".."]
    end

    def directory?(path)
        File.directory? File.join(@root, path)
    end

    def file?(path)
        File.file? File.join(@root, path)
    end

    def executable?(path)
        result = File.executable?(File.join(@root, path))
        $LOGGER.debug("Is #{path} executable = #{result}")
        return result
    end

    def read_file(path)
        $LOGGER.debug("Read file by #{path}")
        IO.read(File.join(@root, path))
    end

    # Write to a file
    def can_write?(path)
        result = write?(path)
        $LOGGER.debug("Can write #{path} = #{result}")
        return result
    end

    def write_to(path, data)
        $LOGGER.debug("Write to path:#{path} data:#{data}")
        File.open(File.join(@root, path), "w+") do |file|
            file.write(data)
        end
    end

    # Delete a file
    def can_delete?(path)
        result = write?(path)
        $LOGGER.debug("Can delete file path : #{path} = #{result}")
        return result
    end

    def delete(path)
        $LOGGER.debug("Delete path: #{path}")
        File.delete(File.join(@root, path))
    end

    # Make a new directory
    def can_mkdir?(path)
        result = write?(path)
        $LOGGER.debug("Can mkdir path : #{path} = #{result}")
        return result
    end

    def mkdir(path, dir = nil)
        $LOGGER.debug("Mkdir path: #{path} dir #{dir}")
        real_path = File.join(@root, path)
        real_path += dir unless dir == nil
        Dir.mkdir(real_path) 
    end


    # Delete an existing directory.
    def can_rmdir?(path)
        result = write?(path)
        $LOGGER.debug("Can rmdir path : #{path} = #{result}")
        return result
    end

    def rmdir(path)
        $LOGGER.debug("Rmdir path: #{path}")
        Dir.rmdir(File.join(@root, path))
    end

    def size(path)
        size = File.size(File.join(@root, path))
        $LOGGER.debug("Size of file #{path} size = #{size}")
        return size
    end

    def raw_open(path, mode)
            $LOGGER.debug("Open file path = #{path}, mode = #{mode}")
            return true if @files.has_key?(path)
            @files[path] = File.open(File.join(@root, path), mode)
            return true
        rescue
            $LOGGER.error("Failed to open file #{path}")
            return false
    end

    def raw_read(path, off, size)
            $LOGGER.debug("Raw read file #{path}")
            file = @files[path]
            return unless file
            $LOGGER.debug("File is opened raw read path = #{path}, 
                            off = #{off}, size = #{size}")
            file.seek(off, File::SEEK_SET)
            file.read(size)
        rescue
            $LOGGER.error("Failed to raw read file path = #{path}, 
                            off = #{off}, size = #{size}")
            return nil
    end

    def raw_write(path, off, sz, buf)
            $LOGGER.debug("Raw write to file #{path}")
            file = @files[path]
            $LOGGER.debug("Raw write to file = #{file}")
            return unless file
            $LOGGER.debug("File is opened raw write to file path=#{path}, 
                            off = #{off}, size = #{size}, buf = #{buf}")
            file.seek(off, File::SEEK_SET)
            file.write(buf[0, sz])
            file.flush()
        rescue
            $LOGGER.error("Failed to raw write file path = #{path}, 
                            off = #{off}, size = #{size}, buf = #{buf}")
    end

    def raw_close(path)
            $LOGGER.debug("Close file #{path}")
            file = @files[path]
            return unless file
            file.close
            @files.delete path
        rescue
            $LOGGER.error("Failed to close file #{path}")
    end
    
    private
    def write?(path)
        real_path = Pathname.new(File.join(@root, path))
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

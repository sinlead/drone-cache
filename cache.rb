require 'English'

# A Drone CI plugin
class DroneCache
  attr_accessor :key_path, :mount_path, :prefix, :commit_msg, :action

  def initialize
    self.key_path = ENV['PLUGIN_KEY']
    self.mount_path = ENV['PLUGIN_MOUNT']
    self.prefix = ENV['PLUGIN_PREFIX'] || 'drone-cache'
    self.action = ENV['PLUGIN_ACTION']
  end

  def run
    abort("Prefix `#{prefix}` is invalid!") unless prefix_valid?(prefix)

    if action == 'save'
      save
    elsif action == 'load'
      load
    else
      abort("Unknown action: `#{action}`!")
    end
  end

  def save
    finish!('Cache already exists. Skip saving.') if File.exist?(cache_path)

    unless File.exist?(mount_path)
      abort("Cound not found mount dir at: #{mount_path}")
    end

    build_cache_root!
    archive!(mount_path, cache_path)
    finish!('Save cache success!')
  end

  def load
    unless File.exist?(cache_path)
      finish!('Cache file not found. Skip loading.')
    end

    unarchive!(cache_path, mount_path)
    finish!('Load cache success!')
  end

  private

  def prefix_valid?(prefix)
    prefix.to_s.match?(/\A[[:alpha:]]([[:alnum:]]|_|-)+\z/)
  end

  def finish!(message)
    puts(message)
    exit 0
  end

  def unarchive!(src, dist)
    `mkdir -p #{dist} && tar -xf #{src} -C #{dist}`
    check_child_status!("Unarchive from #{src} to #{dist}")
  end

  def archive!(src, dist)
    `tar -cpf #{dist} -C #{src} .`
    check_child_status!("Archive from #{src} to #{dist}")
  end

  def build_cache_root!
    `mkdir -p #{cache_root}`
    check_child_status!("Build cache root")
  end

  def check_child_status!(job_name)
    if $CHILD_STATUS.success?
      puts("#{job_name} success.")
    else
      abort("#{job_name} failed.")
    end
  end

  def cache_root
    @cache_root ||= "/cache/#{prefix}"
  end

  def cache_filename
    @cache_filename ||= "#{checksum}.tar"
  end

  def cache_path
    @cache_path ||= "#{cache_root}/#{cache_filename}"
  end

  def checksum
    @checksum ||= begin
      unless File.exist?(key_path)
        abort("Cound not found source at: #{key_path}")
      end

      checksum =
        `find #{key_path} -type f -exec md5sum {} \\; | sort -k 2 | md5sum`
      abort('Fail when exec checksum') unless $CHILD_STATUS.success?

      checksum.slice(0, 16)
    end
  end
end

DroneCache.new.run

class DroneCache
  attr_accessor :key_path, :mount_path, :prefix, :commit_msg, :action

  def initialize
    self.key_path = ENV['PLUGIN_KEY']
    self.mount_path = ENV['PLUGIN_MOUNT']
    self.prefix = ENV['PLUGIN_PREFIX'] || 'drone-cache'
    self.action = ENV['PLUGIN_ACTION']
  end

  def run
    abort!("Prefix `#{prefix}` is invalid!") unless prefix_valid?(prefix)

    if action == 'save'
      save
    elsif action == 'load'
      load
    else
      abort!("Unknown action: `#{action}`!")
    end
  end

  def save
    finish!('Cache already exists. Skip saving.') if File.exists?(cache_path)

    abort!("Cound not found mount dir at: #{mount_path}") unless File.exists?(mount_path)

    rsync!(mount_path, cache_path)
    finish!('Save cache success!')
  end

  def load
    finish!('Cache file not found. Skip loading.') unless File.exists?(cache_path)

    rsync!(cache_path, mount_path)
    finish!('Load cache success!')
  end

  private

  def prefix_valid?(prefix)
    prefix.to_s.match?(/\A[[:alpha:]]([[:alnum:]]|_|-)+\z/)
  end

  def abort!(message)
    STDERR.puts(message)
    exit 1
  end

  def finish!(message)
    puts(message)
    exit 0
  end

  def rsync!(src, dist)
    is_dir = !File.file?(src)

    src = is_dir ? "#{src}/" : src
    dist_dir = is_dir ? dist : File.dirname(dist)

    job_name = "rsync from #{src} to #{dist}"

    puts("#{job_name} start.")
    %x(mkdir -p #{dist_dir} && rsync -aHA --delete #{src} #{dist})

    if $?.success?
      puts("#{job_name} success.")
    else
      abort!("#{job_name} failed.")
    end
  end

  def cache_root
    @cache_root ||= "/cache/#{prefix}"
  end

  def cache_path
    @cache_path ||= "#{cache_root}/#{checksum}"
  end

  def checksum
    @checksum ||= begin
      abort!("Cound not found source at: #{key_path}") unless File.exists?(key_path)

      checksum = %x(find #{key_path} -type f -exec md5sum {} \\; | sort -k 2 | md5sum)
      abort!('Fail when exec checksum') unless $?.success?

      checksum.slice(0, 16)
    end
  end
end

DroneCache.new.run

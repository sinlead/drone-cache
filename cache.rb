require 'json'

class CacheIt
  attr_accessor :src_path, :dist_path, :prefix, :commit_msg, :action

  def initialize
    puts '--------'

    self.src_path = ENV['PLUGIN_SRC']
    self.dist_path = ENV['PLUGIN_DIST']
    self.prefix = ENV['PLUGIN_PREFIX']
    self.commit_msg = ENV['DRONE_COMMIT_MESSAGE']
    self.action = ENV['PLUGIN_ACTION']

    puts "src_path: #{src_path}"
    puts "dist_path: #{dist_path}"
    puts "prefix: #{prefix}"
    puts "commit_msg: #{commit_msg}"
    puts "action: #{action}"
  end

  def main
    if commit_msg && commit_msg.include?('[NO CACHE]')
      finish!('Found [NO CACHE] in commit message, skipping cache actions!')
    end

    abort!("Prefix `#{prefix}` is invalid!") unless prefix_valid?(prefix)

    if action == 'save'
      save
    elsif action == 'load'
      load
    else
      abort!('Unknown action: `#{action}`!')
    end
  end

  def save
    finish!('Cache already exists. Skip saving.') if File.exists?(cache_path)
    abort!("Cound not found cache target at: #{dist_path}") unless File.exists?(dist_path)

    %x(rsync -aHA --delete #{dist_path} #{cache_path})

    if $?.success?
      finish!('Save cache success!')
    else
      abort!('Save cache fail!')
    end
  end

  def load
    finish!('Cache file not found. Skip loading.') unless File.exists?(cache_path)
    %x(rsync -aHA --delete #{cache_path} #{dist_path})

    if $?.success?
      finish!('Load cache success!')
    else
      abort!('Load cache fail!')
    end
  end

  private

  def prefix_valid?(prefix)
    prefix.to_s.match?(/\A[A-Za-z][A-Za-z0-9_-]+\z/)
  end

  def abort!(message)
    STDERR.puts(message)
    exit 1
  end

  def finish!(message)
    puts(message)
    exit 0
  end

  def cache_path
    @cache_path ||= "/cache/#{prefix}-#{check_sum}"
  end

  def check_sum
    @check_sum ||= begin
      abort! "Cound not found source at: #{src_path}" unless File.exists?(src_path)

      check_sum = %x(tar -cf - #{src_path} | md5sum)
      abort! 'Fail when exec check_sum' unless $?.success?

      check_sum.slice(0, 16)
    end
  end
end

CacheIt.new.main

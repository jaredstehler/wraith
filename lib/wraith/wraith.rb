require 'yaml'

class Wraith::Wraith
  attr_accessor :config

  def initialize(config_name)
    if File.exist?(config_name) && File.extname(config_name) == '.yaml'
      @config = YAML.load(File.open(config_name))
    else
      @config = YAML.load(File.open("configs/#{config_name}.yaml"))
    end
  rescue
    puts 'unable to find config'
    exit 1
  end

  def directory
    # Legacy support for those using array configs
    @config['directory'].is_a?(Array) ? @config['directory'].first : @config['directory']
  end

  def history_dir
    @config['history_dir']
  end

  def snap_file
    @config['snap_file'] ? @config['snap_file'] : File.expand_path('lib/wraith/javascript/snap.js')
  end

  def widths
    @config['screen_widths']
  end

  def domains
    @config['domains']
  end

  def base_domain
    domains[base_domain_label]
  end

  def comp_domain
    domains[comp_domain_label]
  end

  def base_domain_label
    domains.keys[0]
  end

  def comp_domain_label
    domains.keys[1]
  end

  def spider_file
    @config['spider_file'] ? @config['spider_file'] : 'spider.txt'
  end

  def spider_days
    @config['spider_days']
  end

  def sitemap
    @config['sitemap']
  end

  def spider_skips
    @config['spider_skips']
  end

  def paths
    result = {}
    url_num = 0

    if @config['paths_file'] then
      File.foreach(@config['paths_file']) { |line| 
        result["#{url_num}"] = line.strip!
        url_num = url_num + 1
      }
    else
      result = @config['paths']
    end

    result
  end

  def engine
    @config['browser']
  end

  def fuzz
    @config['fuzz']
  end

  def mode
    if %w(diffs_only diffs_first alphanumeric).include?(@config['mode'])
      @config['mode']
    else
      'alphanumeric'
    end
  end

  def threshold
    @config['threshold'] ? @config['threshold'] : 0
  end

  def phantomjs_options
    @config['phantomjs_options']
  end
end

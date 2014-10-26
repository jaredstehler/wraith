require 'wraith'
require 'parallel'

class Wraith::SaveImages
  attr_reader :wraith, :history

  def initialize(config, history = false)
    @wraith = Wraith::Wraith.new(config)
    @history = history
  end

  def directory
    wraith.directory
  end

  def check_paths
    if !wraith.paths
      path = File.read(wraith.spider_file)
      eval(path)
    else
      wraith.paths
    end
  end

  def history_label
    history ? '_latest' : ''
  end

  def engine
    wraith.engine.each { |_label, browser| return browser }
  end

  def engine_label
    wraith.engine.key(engine)
  end

  def base_urls(path)
    "#{wraith.base_domain}" % [path] unless wraith.base_domain.nil?
  end

  def compare_urls(path)
    "#{wraith.comp_domain}" % [path] unless wraith.comp_domain.nil?
  end

  def file_names(width, label, domain_label)
    "#{directory}/#{label}/#{width}_#{engine_label}_#{domain_label}.png"
  end

  def attempt_image_capture(width, url, filename, selector, max_attempts)
    max_attempts.times do |i|
      capture_page_image engine, url, width, filename, selector

      return if File.exist? filename

      puts "Failed to capture image #{filename} on attempt number #{i + 1} of #{max_attempts}"
    end

    fail "Unable to capture image #{filename} after #{max_attempts} attempt(s)"
  end

  def has_casper(options)
    options['path'] ? options['path'] : options
  end

  def casper_selector(options)
    options['selector'] ? options['selector'] : ' '
  end

  def save_images
    jobs = []
    check_paths.each do |label, options|
      path = has_casper(options)
      selector = casper_selector(options)

      base_url = base_urls(path)
      compare_url = compare_urls(path)

      puts base_url

      wraith.widths.each do |width|
        base_file_name    = file_names(width, label, "#{wraith.base_domain_label}#{history_label}")
        compare_file_name = file_names(width, label, "#{wraith.comp_domain_label}#{history_label}")

        jobs << [label, path, width, base_url,    base_file_name, selector]
        jobs << [label, path, width, compare_url, compare_file_name, selector] unless compare_url.nil?
      end
    end
    parallel_task(jobs)
  end

  def parallel_task(jobs)
    Parallel.each(jobs, in_threads: 8) do |_label, _path, width, url, filename, selector|
      begin
        attempt_image_capture(width, url, filename, selector, 5)
      rescue => e
        puts e

        puts 'Using fallback image instead'
        invalid = File.expand_path('../../assets/invalid.jpg', File.dirname(__FILE__))
        FileUtils.cp invalid, filename

        # Set width of fallback image
        set_image_width(filename, width)
      end
    end
  end

  def set_image_width(image, width)
    `convert #{image} -background none -extent #{width}x0 #{image}`
  end

  def capture_page_image(browser, url, width, file_name, selector)
    puts `"#{browser}" "#{wraith.phantomjs_options}" "#{wraith.snap_file}" "#{url}" "#{width}" "#{file_name}" "#{selector}"`
  end
end

require "net/http"
require "json"

class GithubBottle
  def initialize(brew_project_name, project_basepath, authorization)
    @authorization = authorization
    @brew_project_name = brew_project_name
    @project_basepath = project_basepath
    @project_basepath << "/" unless project_basepath.end_with?("/")

    @has_checked_bottle = false
    @has_bottle = false
    @bottle_asset_id = -1
  end

  attr_accessor :release_uri
  attr_accessor :project_basepath

  def file_pattern(formula)
    "#{formula.name}-#{formula.pkg_version}.#{bottle_tag}.bottle.tar.gz"
  end

  def inner_bottled?(formula)
    # Get the assets from github for this formula
    release_uri = URI(@project_basepath + "releases/tags/bottles")

    req = Net::HTTP::Get.new(release_uri)

    req["Authorization"] = @authorization

    res = Net::HTTP.start(release_uri.hostname, release_uri.port,
      :use_ssl => release_uri.scheme == "https") do |http|
      http.open_timeout = 2
      http.read_timeout = 2
      http.request(req)
    end

    unless Net::HTTPOK === res
      raise "Failed to connect to #{@release_uri} - #{e.message}"
    end

    release_json = JSON.parse(res.body)

    for asset in release_json["assets"] do
      if asset["name"] === file_pattern(formula)
        @bottle_asset_id = asset["id"]
        ohai "Found a bottle for #{asset["name"]}"
        return true
      end
    end

    false
  rescue Exception => e
    opoo "Something went wrong trying to find the bottle from github - #{e.message}"
    false
  end

  def bottled?(formula)
    if @has_checked_bottle
      return @has_bottle
    end

    @has_checked_bottle = true
    @has_bottle = inner_bottled?(formula)
    return @has_bottle
  end

  def pour(formula)
    asset_uri = URI(@project_basepath + "releases/assets/#{@bottle_asset_id}")

    name = formula.name
    here_cache = (HOMEBREW_CACHE/@brew_project_name)
    here_cache.mkpath
    file = file_pattern formula
    cache_file = here_cache/file

    ohai "brew-github-bottles: Downloading #{asset_uri}"
    success = false

    # Get the asset from github
    req = Net::HTTP::Get.new(asset_uri)

    req["Authorization"] = @authorization
    req["Accept"] = "application/octet-stream"

    res = Net::HTTP.start(asset_uri.hostname, asset_uri.port,
      :use_ssl => asset_uri.scheme == "https") do |http|
      http.open_timeout = 5
      http.read_timeout = 5
      http.request(req)
    end

    data = ""
    begin
      case res
        when Net::HTTPSuccess then
          data = res.body
        when Net::HTTPRedirection then
          res = Net::HTTP.get_response(URI(res["location"]))
          unless Net::HTTPOK === res
            raise
          end
          data = res.body
        else
          raise
      end
    rescue Exception => e
      puts e.backtrace.inspect
      raise "brew-github-bottles: Failed to download resource \"#{name}\" (#{e.message})"
    end

    open cache_file, "w" do |io|
      io.write res.body
    end

    bottle_install_dir = formula.prefix
    bottle_install_dir.mkpath

    ohai "brew-github-bottles: Pouring #{file} to #{bottle_install_dir}"

    # TODO: Use Minitar instead?
    system "tar", "-xf", cache_file, "-C", bottle_install_dir, "--strip-components=2"
    true
  end
end

require 'spec_helper'
require 'fileutils'

RELATIVE_DIRNAME = File.dirname(__FILE__)
RELEASE_RESPONSE = File.open(File.expand_path('./fixtures/release_response.json', RELATIVE_DIRNAME)) { |f| f.read }
UNTAR_FIXTURE = File.open(File.expand_path('./fixtures/test_untar.txt', RELATIVE_DIRNAME)) { |f| f.read }

describe GithubBottle do
  before(:each) do
    @cache_root = Pathname(Dir.mktmpdir('brew-github-bottles'))

    @formula = double("formula")
    allow(@formula).to receive(:name) { "test-bottle" }
    allow(@formula).to receive(:pkg_version) { "1.0.0" }
    allow(@formula).to receive(:prefix) { @cache_root/"test-bottle" }

    # instance variable so that we reopen the file each time.
    @get_release_response = File.new(File.expand_path('./fixtures/get_release_response.tar', RELATIVE_DIRNAME))
  end

  after(:each) do
    FileUtils.rm_rf(@cache_root)
  end

  it 'should append a / to the base path' do
    bottle = GithubBottle.new('https://api.github.com')
    expect(bottle.project_basepath).to eq 'https://api.github.com/'
  end

  it 'should return true is there is a bottle' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')

    stub_request(:get, "https://api.github.com/releases/tags/bottles").
         with(:headers => {'Authorization'=>'token foo'}).to_return(:status => 200, :body => RELEASE_RESPONSE)

    bottled = bottle.bottled?(@formula)
    expect(bottled).to eq true
  end

  it 'should return false is there is no bottle' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')

    stub_request(:get, "https://api.github.com/releases/tags/bottles").
         with(:headers => {'Authorization'=>'token foo'}).to_return(:status => 200, :body => RELEASE_RESPONSE)

    not_found_formula = double("formula")
    allow(not_found_formula).to receive(:name) { 'not-found-bottle' }
    allow(not_found_formula).to receive(:pkg_version) { "1.0.0" }

    bottled = bottle.bottled?(not_found_formula)
    expect(bottled).to eq false
  end

  it 'should return false if there is an error checking for a bottle' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')

    stub_request(:get, "https://api.github.com/releases/tags/bottles").
         with(:headers => {'Authorization'=>'token foo'}).to_raise(StandardError)

    bottled = bottle.bottled?(@formula)
    expect(bottled).to eq false
  end

  it 'should return false if there is an HTTP error' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')
    bottle.bottle_asset_id = 123456

    stub_request(:get, "https://api.github.com/releases/tags/bottles").
         with(:headers => {'Authorization'=>'token foo'}).to_return(:status => 500)

    bottled = bottle.bottled?(@formula)
    expect(bottled).to eq false
  end

  it 'should only check once for bottles' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')
    stub_get = stub_request(:get, "https://api.github.com/releases/tags/bottles").
         with(:headers => {'Authorization'=>'token foo'}).to_return(:status => 200, :body => RELEASE_RESPONSE)

    bottled = bottle.bottled?(@formula)
    expect(bottled).to eq true

    remove_request_stub(stub_get)

    # Should succeed, even if there is no stub
    bottled = bottle.bottled?(@formula)
    expect(bottled).to eq true
  end

  def ensure_untar
    untar_file = @formula.prefix/"test_untar.txt"

    expect(untar_file).to exist
    untar_test = File.open(untar_file) { |f| f.read }
    expect(untar_test).to eq UNTAR_FIXTURE
  end

  it 'should pour a bottle' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')
    bottle.bottle_asset_id = 123456

    stub_request(:get, "https://api.github.com/releases/assets/123456").
         with(:headers => {'Accept'=>'application/octet-stream', 'Authorization'=>'token foo'}).
         to_return(:status => 200, :body => @get_release_response)

    bottle.pour(@cache_root, @formula)
    ensure_untar
  end

  it 'should pour a bottle from a redirect' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')
    bottle.bottle_asset_id = 123456

    stub_request(:get, "https://api.github.com/releases/assets/123456").
         with(:headers => {'Accept'=>'application/octet-stream'}).
         to_return(:status => 302, :headers => { 'Location' => "https://api.github.com/releases/assets/redirect"})

    stub_request(:get, "https://api.github.com/releases/assets/redirect").
         to_return(:status => 200, :body => @get_release_response)

    bottle.pour(@cache_root, @formula)
    ensure_untar
  end

  it 'should not require authorization to pour a bottle' do
    bottle = GithubBottle.new('https://api.github.com')
    bottle.bottle_asset_id = 123456

    stub_request(:get, "https://api.github.com/releases/assets/123456").
         with(:headers => {'Accept'=>'application/octet-stream'}).
         to_return(:status => 200, :body => @get_release_response)

    bottle.pour(@cache_root, @formula)
    ensure_untar
  end

  it 'should fail to pour if no bottle exists' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')
    bottle.bottle_asset_id = 123456

    stub_request(:get, "https://api.github.com/releases/assets/123456").
         with(:headers => {'Accept'=>'application/octet-stream', 'Authorization'=>'token foo'}).
         to_return(:status => 404)

    expect {bottle.pour(@cache_root, @formula)}.to raise_error(GithubBottle::Error)
  end

  it 'should fail to pour if there is an HTTP error' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')
    bottle.bottle_asset_id = 123456

    stub_request(:get, "https://api.github.com/releases/assets/123456").
         with(:headers => {'Accept'=>'application/octet-stream', 'Authorization'=>'token foo'}).
         to_return(:status => 500)

    expect {bottle.pour(@cache_root, @formula)}.to raise_error(GithubBottle::Error)
  end

  it 'should fail to pour if there is an error' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')
    bottle.bottle_asset_id = 123456

    stub_request(:get, "https://api.github.com/releases/assets/123456").
         with(:headers => {'Accept'=>'application/octet-stream', 'Authorization'=>'token foo'}).
         to_raise(GithubBottle::Error)

    expect {bottle.pour(@cache_root, @formula)}.to raise_error(GithubBottle::Error)
  end

  it 'should fail to pour if there is an error in a redirect' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')
    bottle.bottle_asset_id = 123456

    stub_request(:get, "https://api.github.com/releases/assets/123456").
         with(:headers => {'Accept'=>'application/octet-stream'}).
         to_return(:status => 302, :headers => { 'Location' => "https://api.github.com/releases/assets/redirect"})

    stub_request(:get, "https://api.github.com/releases/assets/redirect").
         to_return(:status => 500)

    expect {bottle.pour(@cache_root, @formula)}.to raise_error(GithubBottle::Error)
  end
end

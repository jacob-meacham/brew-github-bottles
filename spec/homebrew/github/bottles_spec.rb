require 'spec_helper'

release_response = File.open(File.expand_path('./fixtures/release_response.json', File.dirname(__FILE__))) { |f| f.read }

describe GithubBottle do
  before(:each) do
    @formula = double("formula")
    allow(@formula).to receive(:name) { "test-bottle" }
    allow(@formula).to receive(:pkg_version) { "1.0.0" }
  end

  it 'should append a / to the base path' do
    bottle = GithubBottle.new('https://api.github.com')
    expect(bottle.project_basepath).to eq('https://api.github.com/')
  end

  it 'should return true is there is a bottle' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')

    stub_request(:get, "https://api.github.com/releases/tags/bottles").
         with(:headers => {'Authorization'=>'token foo'}).to_return(:status => 200, :body => release_response)

    bottled = bottle.bottled?(@formula)
    expect(bottled).to eq(true)
  end

  it 'should return false is there is no bottle' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')

    stub_request(:get, "https://api.github.com/releases/tags/bottles").
         with(:headers => {'Authorization'=>'token foo'}).to_return(:status => 200, :body => release_response)

    not_found_formula = double("formula")
    allow(not_found_formula).to receive(:name) { 'not-found-bottle' }
    allow(not_found_formula).to receive(:pkg_version) { "1.0.0" }

    bottled = bottle.bottled?(not_found_formula)
    expect(bottled).to eq(false)
  end

  it 'should return false if there is an error checking for a bottle' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')

    stub_request(:get, "https://api.github.com/releases/tags/bottles").
         with(:headers => {'Authorization'=>'token foo'}).to_raise(StandardError)

    bottled = bottle.bottled?(@formula)
    expect(bottled).to eq(false)
  end

  it 'should only check once for bottles' do
    bottle = GithubBottle.new('https://api.github.com', 'token foo')
    stub_get = stub_request(:get, "https://api.github.com/releases/tags/bottles").
         with(:headers => {'Authorization'=>'token foo'}).to_return(:status => 200, :body => release_response)

    bottled = bottle.bottled?(@formula)
    expect(bottled).to eq(true)

    remove_request_stub(stub_get)

    # Should succeed, even if there is no stub
    bottled = bottle.bottled?(@formula)
    expect(bottled).to eq(true)
  end

  it 'should pour a bottle' do
  end

  it 'should not require authorization to pour a bottle' do
  end

  it 'should fail to pour if no bottle exists' do
  end
end

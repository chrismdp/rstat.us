require_relative '../test_helper'

require 'rack/test'

VCR.config do |c|
  c.cassette_library_dir = 'test/data/vcr_cassettes'
  c.stub_with :webmock
end

module AcceptanceHelper
  require 'capybara/dsl'
  require 'capybara/rails'
  include Capybara::DSL
  include Rack::Test::Methods
  include TestHelper

  OmniAuth.config.test_mode = true

  def app() Rstatus end

  def setup
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
    Capybara.reset_sessions!
  end

  def omni_mock(username, options={})
    provider = (options[:provider] || :twitter).to_sym
    return OmniAuth.config.add_mock(provider, auth_response(username, options))
  end

  def log_in(user, uid = 12345)
    if user.is_a? User
      user = user.username
    end

    omni_mock(user, {:uid => uid})

    visit '/auth/twitter'
  end

  def log_in_fb(user, uid = 12345)
    if user.is_a? User
      user = user.username
    end

    omni_mock(user, {:uid => uid, :provider => :facebook})

    visit '/auth/facebook'
  end

  def log_in_email(user)
    User.stubs(:authenticate).returns(user)

    visit "/login"

    within("form") do
      fill_in "username", :with => user.username
      fill_in "password", :with => "anything"
    end

    click_button "Log in"
  end
end

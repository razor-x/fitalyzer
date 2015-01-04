# Standard library
require 'tmpdir'

require 'guard'

destination = '_site/'

# Set `rake build` as default task
task default: :build

# Redefine system to exit with nonzero status on fail.
def system(*args)
  super(*args) or exit!(1)
end

task build: [:html]

desc 'Compile web app.'
task :html do
  Guard.setup
  %i(sprockets haml).each do |guard|
    Guard.state.session.plugins.all(guard).each { |g| g.run_all }
  end
  FileUtils.copy 'bower_components/zeroclipboard/ZeroClipboard.swf', '_site'
  puts '# -> _site/ZeroClipboard.swf'
end

desc 'Compile and publish to GitHub Pages.'
task :ghpages do
  repo = %x(git config remote.origin.url).strip
  deploy_branch = repo.match(/github\.io\.git$/) ? 'master' : 'gh-pages'
  rev = %x(git rev-parse HEAD).strip

  system 'bundle update'
  system 'bower update'

  Dir.mktmpdir do |dir|
    system "git clone --branch #{deploy_branch} #{repo} #{dir}"
    system 'bundle exec rake build'
    system %Q(rsync -rt --delete-after --exclude=".git" --exclude=".nojekyll" #{destination} #{dir})
    Dir.chdir dir do
      system 'git add --all'
      system "git commit -m 'Built from #{rev}'."
      system 'git push'
    end
  end
end

desc 'Generate site from Travis CI and publish site to GitHub Pages.'
task :travis do
  # if this is a pull request, do a simple build of the site and stop
  if ENV['TRAVIS_PULL_REQUEST'].to_s.to_i > 0
    puts 'Pull request detected. Executing build only.'
    system 'bundle exec rake build'
    next
  end

  repo = %x(git config remote.origin.url).gsub(/^git:/, 'https:').strip
  deploy_url = repo.gsub %r{https://}, "https://#{ENV['GH_TOKEN']}@"
  deploy_branch = repo.match(/github\.io\.git$/) ? 'master' : 'gh-pages'
  rev = %x(git rev-parse HEAD).strip

  Dir.mktmpdir do |dir|
    dir = File.join dir, 'site'
    system 'bundle exec rake build'
    fail "Build failed." unless Dir.exists? destination
    system "git clone --branch #{deploy_branch} #{repo} #{dir}"
    system %Q(rsync -rt --del --exclude=".git" --exclude=".nojekyll" #{destination} #{dir})
    Dir.chdir dir do
      # setup credentials so Travis CI can push to GitHub
      system "git config user.name '#{ENV['GIT_NAME']}'"
      system "git config user.email '#{ENV['GIT_EMAIL']}'"

      system 'git add --all'
      system "git commit -m 'Built from #{rev}'."
      system "git push -q #{deploy_url} #{deploy_branch}"
    end
  end
end

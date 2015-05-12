require 'guard'

destination = '_site/'

task default: :build

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

  sh 'bundle update'
  sh 'bower update'

  Dir.mktmpdir do |dir|
    sh "git clone --branch #{deploy_branch} #{repo} #{dir}"
    sh 'bundle exec rake build'
    sh %Q(rsync -rt --delete-after --exclude=".git" --exclude=".nojekyll" --exclude=".deploy_key*" #{destination} #{dir})
    Dir.chdir dir do
      sh 'git add --all'
      sh "git commit -m 'Built from #{rev}'."
      sh 'git push'
    end
  end
end

# rake travis
desc 'Compile on Travis CI and publish site to GitHub Pages.'
task :travis do
  # if this is a pull request, do a simple build of the site and stop
  if ENV['TRAVIS_PULL_REQUEST'].to_s.to_i > 0
    puts 'Pull request detected. Executing build only.'
    sh 'bundle exec rake build'
    next
  end

  verbose false do
    sh 'chmod 600 .deploy_key'
    sh 'ssh-add .deploy_key'
  end

  repo = %x(git config remote.origin.url)
         .gsub(%r{^git://}, 'git@')
         .sub(%r{/}, ':').strip
  deploy_branch = repo.match(/github\.io\.git$/) ? 'master' : 'gh-pages'
  rev = %x(git rev-parse HEAD).strip

  Dir.mktmpdir do |dir|
    dir = File.join dir, 'site'
    sh 'bundle exec rake build'
    fail "Build failed." unless Dir.exists? destination
    sh "git clone --branch #{deploy_branch} #{repo} #{dir}"
    sh %Q(rsync -rt --del --exclude=".git" --exclude=".nojekyll" --exclude=".deploy_key*" #{destination} #{dir})
    Dir.chdir dir do
      # setup credentials so Travis CI can push to GitHub
      verbose false do
        sh "git config user.name '#{ENV['GIT_NAME']}'"
        sh "git config user.email '#{ENV['GIT_EMAIL']}'"
      end

      sh 'git add --all'
      sh "git commit -m 'Built from #{rev}'."

      verbose false do
        sh "git push -q #{repo} #{deploy_branch}"
      end
    end
  end
end

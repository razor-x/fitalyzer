require 'coffee_script'
require 'sass'

def sprockets_config type, root_file, minify: true
  {
    destination: '_site',
    asset_paths: [File.join('app', type), 'bower_components'],
    root_file: root_file,
    minify: minify
  }
end

guard :sprockets, sprockets_config('javascripts', ['app.js', 'head.js']) do
  watch %r{app/javascripts/(.+).(js|coffee)$}
end

guard :sprockets, sprockets_config('stylesheets', 'app.css') do
  watch %r{app/stylesheets/(.+).(css|sass)$}
end

guard :haml, input: 'app', output: '_site', run_at_start: true do
  watch %r{\.haml$}
end

guard :webrick, docroot: '_site', launchy: false

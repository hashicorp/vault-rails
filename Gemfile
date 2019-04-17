def gem_source
  user     = ENV.fetch('GEM_USER')
  password = ENV.fetch('GEM_PASSWORD')
  url      = 'artifactory.lkeymgmt.com/artifactory/api/gems/gems/'
  "https://#{user}:#{password}@#{url}"
end

source gem_source

gemspec

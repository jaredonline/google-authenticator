version_info = RUBY_VERSION.split(".")

major  = version_info.first.to_i
minor  = version_info[1].to_i
hotfix = version_info.last.to_i

appraise "rails-6.1" do
  gem "activerecord", "~> 6.1.0"
end

appraise "rails-7.0" do
  gem "activerecord", "~> 7.0.0"
end
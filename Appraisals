version_info = RUBY_VERSION.split(".")

major  = version_info.first.to_i
minor  = version_info[1].to_i
hotfix = version_info.last.to_i

if major < 2
  appraise "rails2.3" do
    gem "activerecord", "~> 2.3.8"
  end
end

appraise "rails3.0" do
  gem "activerecord", "~> 3.0.0"
end

appraise "rails3.1" do
  gem "activerecord", "~> 3.1.0"
end

appraise "rails3.2." do
  gem "activerecord", "~> 3.2.0"
end

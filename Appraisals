version_info = RUBY_VERSION.split(".")

major  = version_info.first.to_i
minor  = version_info[1].to_i
hotfix = version_info.last.to_i

appraise "rails3.0" do
  gem "activerecord", "~> 3.0.0"
end

appraise "rails3.1" do
  gem "activerecord", "~> 3.1.0"
end

appraise "rails3.2" do
  gem "activerecord", "~> 3.2.0"
end

appraise "rails4.0" do
  gem "activerecord", "~> 4.0.0"
  gem "protected_attributes"
end

appraise "rails4.1" do
  gem "activerecord", "~> 4.1.0"
  gem "protected_attributes"
end

appraise "rails4.2" do
  gem "activerecord", "~> 4.2.0"
end

appraise "rails5.0" do
  gem "activerecord", "~> 5.0.0"
end

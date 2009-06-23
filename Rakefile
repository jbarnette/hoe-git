$: << "lib"

require "rubygems"
require "hoe"

Hoe.plugin :git

Hoe.spec "hoe-git" do
  developer "John Barnette", "jbarnette@rubyforge.org"

  self.extra_rdoc_files = FileList["*.rdoc"]
  self.history_file     = "CHANGELOG.rdoc"
  self.readme_file      = "README.rdoc"

  extra_deps << ["hoe", ">= 2.2.0"]
end

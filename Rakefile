$: << "lib"

require "rubygems"
require "hoe"

Hoe.plugin :doofus, :git

Hoe.spec "hoe-git" do
  developer "John Barnette", "jbarnette@rubyforge.org"

  self.extra_rdoc_files = FileList["*.rdoc"]
  self.history_file     = "CHANGELOG.rdoc"
  self.readme_file      = "README.rdoc"

  rdoc_locations <<
    'docs.seattlerb.org:/data/www/docs.seattlerb.org/hoe-git'
end

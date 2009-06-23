# Tasks provided:
#
# * <tt>git:tag</tt> -- Tag the current version and push the tag to
#   all the <tt>git_remotes</tt>. This task is added as a dependency
#   of the built-in <tt>release</tt> task. The tag will be
#   <tt>"v#{version}"</tt> unless <tt>TAG</tt> or <tt>VERSION</tt> are
#   set in the environment.

module Hoe::Git
  VERSION = "1.0.0"

  ##
  # Optional: Which remotes do you want to push tags, etc. to?
  # [default: %w(origin)]

  attr_accessor :git_remotes

  def initialize_git
    self.git_remotes = %w(origin)
  end

  def define_git_tasks
    desc "Create and push a TAG (default v#{version})."
    task "git:tag" do
      tag = ENV["TAG"] || "v#{ENV["VERSION"] || version}"

      sh "git tag -f #{tag}"
      git_remotes.each { |remote| sh "git push -f #{remote} tag #{tag}" }
    end

    task :release => "git:tag"
  end
end

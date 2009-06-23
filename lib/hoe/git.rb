# Tasks provided:
#
# * <tt>git:tag</t> -- Tag the current version and push the tag to all
#   the <tt>git_remotes</tt>. This task is added as a dependency of
#   the built-in <tt>release</tt> task.

module Hoe::Git
  VERSION = "1.0.0"

  ##
  # Optional: Which remotes do you want to push tags, etc to?
  # [default: %w(origin)]

  attr_accessor :git_remotes

  def initialize_git
    self.git_remotes = %w(origin)
  end

  def define_git_tasks
    desc "Create and push a v#{version} tag."
    task "git:tag" do
      t = "v#{version}"
      v = ENV["VERSION"] || version

      warn "git tag -f #{t}"
      git_remotes.each { |r| warn "git push -f #{r} tag #{t}" }
    end

    task :release => "git:tag"
  end
end

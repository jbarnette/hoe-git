# Tasks provided:
#
# * <tt>git:tag</tt> -- Tag the current version and push the tag to
#   all the <tt>git_remotes</tt>. This task is added as a dependency
#   of the built-in <tt>release</tt> task. The tag will be
#   <tt>"v#{version}"</tt> unless <tt>TAG</tt> or <tt>VERSION</tt> are
#   set in the environment.
#
# * <tt>git:changelog</tt> -- Format a changelog of all the commits
#   since the last release, or since the <tt>FROM</tt> env var if it's
#   provided. Commits that weren't made by a project developer are
#   attributed.

module Hoe::Git
  VERSION = "1.1.1"

  ##
  # Optional: What do you want at the front of your release tags?
  # [default: "v"]

  attr_accessor :git_release_tag_prefix

  ##
  # Optional: Which remotes do you want to push tags, etc. to?
  # [default: %w(origin)]

  attr_accessor :git_remotes

  def initialize_git
    self.git_release_tag_prefix = "v"
    self.git_remotes            = %w(origin)
  end

  def define_git_tasks
    desc "Print the current changelog."
    task "git:changelog" do
      tags  = `git tag -l '#{git_release_tag_prefix}*'`.split "\n"
      tag   = ENV["FROM"] || tags.last
      range = [tag, "HEAD"].compact.join ".."
      cmd   = "git log #{range} '--format=tformat:%s|||%cN|||%cE'"

      changes = `#{cmd}`.split("\n").map do |line|
        msg, author, email = line.split("|||").map { |e| e.empty? ? nil : e }

        developer = author.include?(author) || email.include?(email)
        change    = [msg]
        change   << "[#{author || email}]" unless developer

        change.join " "
      end

      puts "=== #{ENV["VERSION"] || 'NEXT'} / #{Time.new.strftime '%Y-%m-%d'}"
      puts

      changes.each do |change|
        puts "* #{change}"
      end
    end

    desc "Create and push a TAG (default v#{version})."
    task "git:tag" do
      tag   = ENV["TAG"]
      tag ||= "#{git_release_tag_prefix}#{ENV["VERSION"] || version}"

      sh "git tag -f #{tag}"
      git_remotes.each { |remote| sh "git push -f #{remote} tag #{tag}" }
    end

    task :release => "git:tag"
  end
end

class Hoe #:nodoc:

  # This module is a Hoe plugin. You can set its attributes in your
  # Rakefile Hoe spec, like this:
  #
  #    Hoe.plugin :git
  #
  #    Hoe.spec "myproj" do
  #      self.git_release_tag_prefix = "REL_"
  #      self.git_remotes << "myremote"
  #    end

  module Git

    # Duh.
    VERSION = "1.1.3"

    # What do you want at the front of your release tags?
    # [default: <tt>"v"</tt>]

    attr_accessor :git_release_tag_prefix

    # Which remotes do you want to push tags, etc. to?
    # [default: <tt>%w(origin)</tt>]

    attr_accessor :git_remotes

    def initialize_git #:nodoc:
      self.git_release_tag_prefix = "v"
      self.git_remotes            = %w(origin)
    end

    def define_git_tasks #:nodoc:
      return unless File.exist? ".git"

      desc "Print the current changelog."
      task "git:changelog" do
        tags  = git_tags
        tag   = ENV["FROM"] || tags.last
        range = [tag, "HEAD"].compact.join ".."
        cmd   = "git log #{range} '--format=tformat:%s|||%aN|||%aE'"

        changes = `#{cmd}`.split("\n").map do |line|
          msg, author, email = line.split("|||").map { |e| e.empty? ? nil : e }
          developer = self.author.include?(author) ||
            self.email.include?(email)

          change = [msg]
          change << "[#{author || email}]" unless developer

          change.join " "
        end

        next if changes.empty?

        puts "=== #{ENV["VERSION"] || 'NEXT'} / #{Time.new.strftime '%Y-%m-%d'}"
        puts

        changes.each { |change| puts "* #{change}" }
      end

      desc "Create and push a TAG " +
           "(default #{git_release_tag_prefix}#{version})."

      task "git:tag" do
        tag   = ENV["TAG"]
        tag ||= "#{git_release_tag_prefix}#{ENV["VERSION"] || version}"

        git_tag_and_push tag
      end

      task :release_sanity do
        unless `git status` =~ /^nothing to commit/
          abort "Won't release: Dirty index or untracked files present!"
        end
      end

      task :release => "git:tag"

    end

    def git_svn?
      File.exist? ".git/svn"
    end

    def git_tag_and_push tag
      if git_svn?
        sh "git svn tag #{tag} -m 'Tagging #{tag} release.'"
      else
        sh "git tag -f #{tag}"
        git_remotes.each { |remote| sh "git push -f #{remote} tag #{tag}" }
      end
    end

    def git_tags # FIX: order by date, not alpha!
      if git_svn?
        source = `git config svn-remote.svn.tags`.strip

        unless source =~ %r{refs/remotes/(.*)/\*$}
          abort "Can't discover git-svn tag scheme from #{source}"
        end

        prefix = $1

        `git branch -r`.split("\n").
          collect { |t| t.strip }.
          select  { |t| t =~ %r{^#{prefix}/#{git_release_tag_prefix}} }
      else
        `git tag -l '#{git_release_tag_prefix}*'`.split "\n"
      end
    end
  end
end

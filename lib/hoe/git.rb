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
    VERSION = "1.1.2"

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

        changes.each { |change| puts "* #{change}" }
      end

      desc "Create and push a TAG " +
           "(default #{git_release_tag_prefix}#{version})."

      task "git:tag" do
        tag   = ENV["TAG"]
        tag ||= "#{git_release_tag_prefix}#{ENV["VERSION"] || version}"

        sh "git tag -f #{tag}"
        git_remotes.each { |remote| sh "git push -f #{remote} tag #{tag}" }
      end

      task :release_sanity do
        unless `git status` =~ /^nothing to commit/
          abort "Won't release: Dirty index or untracked files present!"
        end
      end

      task :release => "git:tag"

    end
  end
end

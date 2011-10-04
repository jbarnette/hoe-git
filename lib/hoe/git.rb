class Hoe #:nodoc:

  # This module is a Hoe plugin. You can set its attributes in your
  # Rakefile Hoe spec, like this:
  #
  #    Hoe.plugin :git
  #
  #    Hoe.spec "myproj" do
  #      self.git_release_tag_prefix  = "REL_"
  #      self.git_remotes            << "myremote"
  #    end
  #
  #
  # === Tasks
  #
  # git:changelog:: Print the current changelog.
  # git:manifest::  Update the manifest with Git's file list.
  # git:tag::       Create and push a tag.

  module Git

    # Duh.
    VERSION = "1.4.0"

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
        tag   = ENV["FROM"] || git_tags.last
        range = [tag, "HEAD"].compact.join ".."
        cmd   = "git log #{range} '--format=tformat:%B|||%aN|||%aE|||'"
        now   = Time.new.strftime "%Y-%m-%d"

        changes = `#{cmd}`.split(/\|\|\|/).each_slice(3).map do |msg, author, email|
          msg.split(/\n/).reject { |s| s.empty? }
        end

        changes = changes.flatten

        next if changes.empty?

        $changes = Hash.new { |h,k| h[k] = [] }

        codes = {
          "!" => :major,
          "+" => :minor,
          "*" => :minor,
          "-" => :bug,
          "?" => :unknown,
        }

        codes_re = Regexp.escape codes.keys.join

        changes.each do |change|
          if change =~ /^\s*([#{codes_re}])\s*(.*)/ then
            code, line = codes[$1], $2
          else
            code, line = codes["?"], change.chomp
          end

          $changes[code] << line
        end

        puts "=== #{ENV['VERSION'] || 'NEXT'} / #{now}"
        puts
        changelog_section :major
        changelog_section :minor
        changelog_section :bug
        changelog_section :unknown
        puts
      end


      desc "Update the manifest with Git's file list. Use Hoe's excludes."
      task "git:manifest" do
        with_config do |config, _|
          files = `git ls-files`.split "\n"
          files.reject! { |f| f =~ config["exclude"] }

          File.open "Manifest.txt", "w" do |f|
            f.puts files.sort.join("\n")
          end
        end
      end

      desc "Create and push a TAG " +
           "(default #{git_release_tag_prefix}#{version})."

      task "git:tag" do
        tag   = ENV["TAG"]
        tag ||= "#{git_release_tag_prefix}#{ENV["VERSION"] || version}"

        git_tag_and_push tag
      end

      task "git:tags" do
        p git_tags
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
      msg = "Tagging #{tag}."

      if git_svn?
        sh "git svn tag #{tag} -m '#{msg}'"
      else
        sh "git tag -f #{tag} -m '#{msg}'"
        git_remotes.each { |remote| sh "git push -f #{remote} tag #{tag}" }
      end
    end

    def git_tags
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
        flags  = "--date-order --simplify-by-decoration --pretty=format:%H"
        hashes = `git log #{flags}`.split(/\n/).reverse
        names  = `git name-rev --tags #{hashes.join " "}`.split(/\n/)
        names  = names.map { |s| s[/tags\/(v.+)/, 1] }.compact
        names  = names.map { |s| s.sub(/\^0$/, '') }
        names.select { |t| t =~ %r{^#{git_release_tag_prefix}} }
      end
    end

    def changelog_section code
      name = {
        :major   => "major enhancement",
        :minor   => "minor enhancement",
        :bug     => "bug fix",
        :unknown => "unknown",
      }[code]

      changes = $changes[code]
      count = changes.size
      name += "s" if count > 1
      name.sub!(/fixs/, 'fixes')

      return if count < 1

      puts "* #{count} #{name}:"
      puts
      changes.sort.each do |line|
        puts "  * #{line}"
      end
      puts
    end
  end
end

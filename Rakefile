# -*- ruby -*-
require 'rake'

product = 'ranguba'
version = '0.1.0'

task :default => :install

include FileUtils::Verbose

prefix = RbConfig::CONFIG['prefix']

dbdir = '/var/db/ranguba'
indexer = 'indexer/ranguba-indexer'
indexer_base = File.basename(indexer)
indexer_path = File.join("#{prefix}/bin", indexer_base)
cron_daily = '/etc/cron.daily/ranguba-indexer-update'
category_file = 'etc/ranguba/category.tsv'
category_path = File.join(prefix, category_file)
category_dir = File.dirname(category_path)

directory dbdir
directory category_dir

desc 'create empty category file stub'
task :category_path => category_path
file(category_path => category_dir) do |t|
  puts "create #{name = t.name}"
  open(name, 'w') do |f|
    f.puts "#URL""\t""TITLE"
  end
end

desc 'install daily cron job to update ranguba index'
task :cron_daily => cron_daily
file cron_daily do |t|
  puts "create #{name = t.name}"
  open(name, File::WRONLY|File::CREAT, 0755) do |f|
    f.puts <<EOF
#!/bin/sh
PREFIX="#{prefix}"
DBDIR="#{dbdir}"
PATH="$PREFIX/bin:$PATH"
cd "$PREFIX"
exec "#{indexer_base}" -c #{category_file} "$DBDIR/index.db"
EOF
  end
end

desc 'install indexer'
task :indexer => indexer_path
file indexer_path => indexer do |t|
  name = t.name
  puts "install #{name}"
  open(name, File::WRONLY|File::CREAT, 0755) do |f|
    f.puts File.read(indexer).sub(/\A#!.*/, "#!#{name}")
  end
end

desc 'install all'
task :install => [:cron_daily, :category_path, :indexer]

desc 'uninstall'
task :uninstall do
  rm_f([indexer_path, cron_daily, category_path])
  rmdir([category_dir, dbdir])
end

FalseProc = proc {false}
def path_matcher(pat)
  if pat and !pat.empty?
    proc {|f| pat.any? {|n| File.fnmatch?(n, f)}}
  else
    FalseProc
  end
end

def install_recursive(srcdir, dest, options = {})
  opts = options.clone
  noinst = opts.delete(:no_install)
  glob = opts.delete(:glob) || "*"
  subpath = (srcdir.size+1)..-1
  prune = skip = FalseProc
  if noinst
    if Array === noinst
      prune = noinst.grep(/#{File::SEPARATOR}/o).map!{|f| f.chomp(File::SEPARATOR)}
      skip = noinst.grep(/\A[^#{File::SEPARATOR}]*\z/o)
    else
      if noinst.index(File::SEPARATOR)
        prune = [noinst]
      else
        skip = [noinst]
      end
    end
    skip |= %w"#*# *~ *.old *.bak *.orig *.rej *.diff *.patch *.core"
    prune = path_matcher(prune)
    skip = path_matcher(skip)
  end
  File.directory?(srcdir) or return rescue return
  paths = [[srcdir, dest, true]]
  found = []
  while file = paths.shift
    found << file
    file, d, dir = *file
    if dir
      files = []
      Dir.foreach(file) do |f|
        src = File.join(file, f)
        d = File.join(dest, dir = src[subpath])
        stat = File.stat(src) rescue next
        if stat.directory?
          files << [src, d, true] if /\A\./ !~ f and !prune[dir]
        else
          files << [src, d, false] if File.fnmatch?(glob, f) and !skip[f]
        end
      end
      paths.insert(0, *files)
    end
  end
  for src, d, dir in found
    if dir
      makedirs(d)
    else
      makedirs(File.dirname(d))
      install src, d, opts
    end
  end
end

desc 'distribution'
task :dist do
  require 'tmpdir'
  require 'shellwords'
  begin
    tmpdir = nil
    Dir.mktmpdir do |dir|
      tmpdir = dir
      target = "#{product}-#{version}"
      dest = File.join(dir, target)
      Dir.mkdir(dest)
      install_recursive(".", dest, no_install: ["tmp/"])
      args = ["tar", "czf", "#{target}.tar.gz", "-C", dir, target]
      puts Shellwords.join(args)
      system(*args)
    end
  ensure
    rm_rf(tmpdir) if tmpdir
  end
end

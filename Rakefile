require 'rubygems'
require 'rake/gempackagetask'

NAME = 'block-mail'
VERS = '0.0.1'

desc 'Package block-mail'
spec = Gem::Specification.new do |s|
  s.name = NAME
  s.version = VERS
  s.platform = Gem::Platform::RUBY
  s.summary = "BlockMail"
  s.description = s.summary
  s.author = "Jun Kikuchi"
  s.email = "kikuchi@bonnou.com"
  s.homepage = "http://bonnou.com/"
  s.files = %w(COPYING CHANGELOG README.rdoc Rakefile) + Dir.glob("{bin,doc,spec,lib}/**/*")
  s.require_path = "lib"
end

Rake::GemPackageTask.new(spec) do |pkg|
end

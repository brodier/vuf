require "bundler/gem_tasks"

Rake::TestTask.new do |t|
  t.libs << 'lib/vuf'
  t.test_files = FileList['test/lib/vuf/*_test.rb']
  t.verbose = true
end


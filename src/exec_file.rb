
require 'pp'
require_relative 'main'

raise ArgumentError, 'you must specify a file' if ARGV.length < 1

lang = EZPZ.new
parser = lang.parser

ARGV.each do |file_path|
  if File.exist?(file_path)
    input = File.open(file_path).read

    tree = parser.parse(input)
    pp tree

    tree.eval
    lang.clear_cache
  end
end

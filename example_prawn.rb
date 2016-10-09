# Example for the rb2py translator.
# Translates Prawn PDF library https://github.com/prawnpdf/prawn
# It expects that the prawn library is in the prawn-ruby subfolder and that is patched
# as described in the prawn-ruby/patches.txt
# Results will be put in the prawn-python folder.
# prawn-python folder is always completely deleted before translation!


require 'fileutils'
require 'pathname'


require 'logger'
$logger = Logger.new STDOUT
$logger.level = Logger::WARN
$logger.formatter = proc do |severity, time, program_name, msg|
  "[#{severity[0]}] #{msg.is_a?(String) ? msg : msg.inspect}\n"
end


$RB2PY_PATH = Pathname.new __dir__
$OUT_PATH = $RB2PY_PATH / 'prawn-python'
FileUtils.rmtree $OUT_PATH


$LINE_WIDTH = 70
def phase_message(msg)
  puts "*" * $LINE_WIDTH
  puts "***#{' '*($LINE_WIDTH-6)}***"
  puts "***#{msg.center $LINE_WIDTH-6}***"
  puts "***#{' '*($LINE_WIDTH-6)}***"
  puts "*" * $LINE_WIDTH
end


require_relative 'rb2py'
require_relative 'pygen/pygen'
$pygen = PythonGenerator.new $OUT_PATH


phase_message "Translating PDF Core..."
$SRC_PATH = $RB2PY_PATH.join "prawn-ruby", "pdf-core-0.6.0", "lib", "pdf"
rb2py 'core', additional:['core/text']


phase_message "Translating TTFunk..."
$SRC_PATH = $RB2PY_PATH.join "prawn-ruby", "ttfunk-1.4.0", "lib"
rb2py 'ttfunk'


phase_message "Translating Prawn..."
$SRC_PATH = $RB2PY_PATH.join "prawn-ruby", "prawn-2.0.3", "lib"
rb2py 'prawn_rb2py'

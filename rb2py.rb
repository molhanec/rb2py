# Performs the transformation

require_relative 'config'
require_relative 'hints'

require 'parser/current'
Parser::Builders::Default.emit_lambda = true

require 'fileutils'
require 'pathname'
require 'pp'
require 'set'

require_relative 'node'
require_relative 'leaves'
require_relative 'dsl-fixes/simple_fixes'
gen_dsl_fixes


# load all parts
for dir in %w[fixes pygen pyfixes]
  Dir.glob(File.join(File.dirname(__FILE__), dir, '*.rb')) do
    |filename|
    require_relative filename
  end
end


class Rb2PyError < StandardError;
end


def make_stop(msg, cls: Rb2PyError, bt: caller, position: nil)
  # make sure we catch exceptions thrown by to_s()
  begin
    self_string = self.to_s
  rescue
    self_string = "self.to_s() thrown exception"
  end
  begin
    msg_string = msg.to_s
  rescue
    msg_string = "msg.to_s() thrown exception"
  end
  begin
    open 'exception.txt', 'wt' do |file|
      file.puts "Self: #{self_string}"
      file.puts "Message: #{msg_string}"
      file.puts "Position: #{position}" if position
    end
  rescue; end
  position = position ? "\n#{position}" : ''
  fail cls, "#{msg_string}\n#{self_string}#{position}", bt
end

def d(msg)
  $logger.debug msg
end

FileUtils.rm_f 'warnings.txt'
$warnings_file = StringIO.new
def w(msg)
  $logger.warn msg
  $warnings_file.puts msg
end

# warns only for the first time
$logger_memory = []
def w1(msg)
  unless $logger_memory.include? msg
    $logger_memory << msg
    w msg
  end
end


$single_fix_was_run = 0


$indent = 0
def indent_str
  '  ' * $indent
end


def rb2ast(filename)
  filename = $SRC_PATH ? "#$SRC_PATH\\#{filename}.rb" : filename + '.rb'
  Parser::CurrentRuby.parse_file(filename)
end


def save_ast(ast, filename)
  filepath = "ast\\#{filename.gsub('\\', '-')}.txt"
  FileUtils.makedirs (File.dirname filepath)
  File.open filepath, 'wt' do
    |file|
    file.write ast
  end
end


def require?(child)
  child.symbol? 'send' and child.children.size == 3 and
      child.first_child.missing? and
      child.second_child.expect_symbol and
      child.second_child.symbol? 'require'
end


def require_relative?(child)
  child.symbol? 'send' and child.children.size == 3 and
      child.first_child.missing? and
      child.second_child.expect_symbol and
      child.second_child.symbol? 'require_relative'
end


def import_path(str_node)
  str_node.expect 'str'
  str_node.expect_len 1
  str_node.child.value
end


def process_toplevel_child(child, basepath, known_imports)
  if child.symbol? 'module'
    return child
  elsif require? child
    w1 "Global import #{import_path child.third_child}"
    return child
  elsif require_relative? child
    path = import_path(child.third_child)
    complete_path = File.join $SRC_PATH ? $SRC_PATH : '', basepath, path
    complete_path = Pathname(complete_path).cleanpath
    if known_imports.include? complete_path
      d "#{complete_path} already imported, skipping…"
      return nil
    else
      d "Importing #{path}, basepath '#{basepath}'"# #{complete_path}"
      known_imports << complete_path
      return import path, basepath, known_imports
    end
  end
  return child
end


$symbols = SortedSet.new
def extract_symbols(node)
  if node.respond_to? :type
    $symbols << node.type.to_s
  end
  if node.respond_to? :children
    node.children.each {|c| extract_symbols(c)}
  end
end


def import(filename, oldbasepath='', known_imports, runnable_script:false)
  ruby_ast = rb2ast oldbasepath + filename
  extract_symbols ruby_ast
  save_ast ruby_ast.to_s, filename

  file_root = UnprocessedNode.new nil, ruby_ast

  if file_root.symbol? 'begin'
    new_children = []
    for child in file_root.children
      basepath = File.dirname filename
      basepath = basepath == '.' ? '' : basepath + File::SEPARATOR
      new_child = process_toplevel_child(child, oldbasepath + basepath, known_imports)
      new_children << new_child if new_child
    end
    file_root.assign_children new_children
  end
  if runnable_script
    file_root = MainScriptModuleNode.new file_root
  end
  file_root
end


def real_rb2py(filename, runnable_script:false, additional:nil)
  known_imports = Set.new
  root = import filename, known_imports, runnable_script:runnable_script
  root_holder = TopLevelNode.new(root)
  if additional
    for another in additional
      root_holder.add_child (import another, known_imports)
    end
  end

  # required for merge_modules to work
  root_holder.fix :fix_module
  root_holder.fix :fix_resolve_fullname
  root_holder.fix :fix_global_imports

  root_holder.merge_modules

  root_holder.fix :fix_class
  root_holder.fix :fix_resolve_fullname
  root_holder.merge_classes

  root_holder.run_fixes
  root_holder.run_python_fixes
  save_ast root_holder.root.to_s_recursive, filename + '-meta'
  root_holder.root.gen
end


def rb2py(filename, runnable_script:false, additional:nil)
  if $rescue_exceptions
    begin
      real_rb2py filename, runnable_script:runnable_script, additional:additional
    rescue Exception => e
      $logger.error e.message
      $logger.error e.backtrace.first
    end
  else
    real_rb2py filename, runnable_script:runnable_script, additional:additional
  end
  $pygen.symbols_export
  File.open 'symbols.txt', 'wt' do
    |file|
    file << $symbols.to_a.join("\n")
  end
end

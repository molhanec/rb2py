require 'fileutils'
require 'set'
require 'stringio'

require_relative '../pyfixes/external_classes'

class PythonGenerator

  # Default Python indentation
  STEP = 4

  attr_reader :generated_files, :imports, :str, :symbols

  def format_symbol(symbol_name)
    "rb2py.to_sym0('#{symbol_name}')"
  end

  class Argument
    def initialize(name, default_value)
      @name = name
      @default_value = default_value
    end
    def gen
      $pygen.write @name
      if @default_value
        $pygen.write '='
        @default_value.gen
      end
    end
  end

  def initialize(base_path)
    @modules = [base_path]
    @fake = base_path.nil?
    if @fake
      @str = StringIO.new
    end
    @files = []
    @indent = 0
    @arguments = []
    @symbols = SortedSet.new
    @generated_files = Set.new
    @imports = SortedSet.new
    @statement_start = false
    @rb2py_imports = SortedSet.new
    @plain_imports = SortedSet.new

    # If none or only space charaters where generated since last indentation,
    # we need to generate "pass" before dedent.
    # We need to have a stack because indents can be nested, so simple flag won't do it.
    @nonspace_output_generated = [nil]
    @inside_for_header = false
    @for_header_start = true
  end

  def argument(name, default_value=nil)
    unless @inside_for_header
      @arguments << Argument.new(name, default_value)
    else
      write name
    end
  end

  def binop(left, op, right)
    indent "#{left} #{op} #{right}"
  end

  def body
    gen_argument_list
    write ':'
    indent_inc
    position_before = current_file.pos if current_file
    yield

    # if there was no output print pass
    pass if current_file and position_before == current_file.pos

    indent_dec
  end

  def call(name, target=nil)
    if target
      unless target.is_a? MissingNode
        target.gen
        write '.'
      else
        target.already_generated = true
      end
    end
    write "#{name}("
    yield if block_given?
    write ")"
  end

  def call_isinstance(&block)
    $pygen.call 'isinstance', MissingNode.new(nil, nil), &block
  end

  def call_parent
    indent "super()"
  end

  def class(class_name, ancestor, decorators=[], includes=[])
    nl; nl
    for decorator in decorators
      indent "@#{decorator}"
    end
    indent "class #{class_name}"
    if ancestor or includes.size > 0
      # add brackets around ancestor's name
      paren do
        first = true
        for an_include in includes
          if first
            first = false
          else
            write ', '
          end
          an_include.gen
        end
        write ', ' if ancestor and includes.size > 0
        ancestor.gen if ancestor
      end
    end
    write ':'
    indented do
      yield
    end
  end

  def py_class_name(name)
    return nil if name == nil

    d "Class name for #{name}"

    # Rename classes which were relocated
    longest_match = 0
    new_name = name.dup
    for extracted_class in $extracted_classes
      extracted_class_fullname = extracted_class.original_fullname.to_s
      d ".. matching against #{extracted_class_fullname}"

      # if this class was directly the extracted class
      if name == extracted_class_fullname
        d ".... matched fully"
        # use just last part of name
        new_name = extracted_class.fullname.last_part
        # and we can quit the search
        break
      elsif name.start_with? extracted_class_fullname and extracted_class_fullname.size > longest_match
        d ".... matched"
        longest_match = extracted_class_fullname.size
        new_name = name[longest_match..-1]
        new_name = new_name[2..-1] while new_name.start_with? '::'
        new_name = "#{extracted_class.fullname.last_part}::#{new_name}"
      end
    end
    if name != new_name
      d ".... renamed to #{new_name}"
    end

    name = external_class new_name, default:new_name
    return name.gsub('::', '.')
  end

  def comment(text)
    indent "# #{text}"
  end

  def current_module
    @modules[-1]
  end

  def current_file
    if @fake
      @str
    else
      @files[-1]
    end
  end

  def elif(*args)
    self.if *args, elif: true
  end

  def for_header
    write 'for '
    @inside_for_header = true
    @for_header_start = true
      yield
    @inside_for_header = false
    write ' in '
  end

  def function(name, decorators=[], generated_block:nil)
    if generated_block.nil?
      generated_block = name.start_with? '_block'
    end
    @statement_start = true unless generated_block
    for decorator in decorators
      indent decorator
    end
    indent("def #{name}", not(generated_block))
    yield
  end

  def gen_argument_list
    paren do
      gen_comma_separated_list @arguments
    end
    @arguments.clear
  end

  def gen_comma_separated_list(list)
    first = true
    for element in list
      write ', ' unless first
      first = false
      element.gen
    end
  end

  def if(condition, when_true, when_false, elif: false)
    it_is_unless = when_true.empty?

    write elif ? 'elif ' : 'if '

    # Don't wrap condition inside ruby_true() if it is already ruby_true or ruby_false
    if (condition.is_a? SendNode and ['ruby_true', 'ruby_false'].include? condition.message_name) or (
      condition.is_a? InstanceTestNode or condition.is_a? NilTestNode
    )

      # negate condition for unless
      write 'not ' if it_is_unless

      condition.gen
    else
      call(it_is_unless ? 'ruby_false' : 'ruby_true', 'rb2py') {
        condition.gen
      }
    end
    write ':'
    indent_inc
    if it_is_unless
      when_false.gen
      when_false = when_true
    else
      when_true.gen
    end
    indent_dec
    if when_false and not when_false.empty?
      indent 'else:'
      indent_inc
      when_false.gen
      indent_dec
    end
  end

  def indent(str=nil, new_line=true)
    if new_line
      nl
      write indent_str
    end
    write str if str
  end

  def indent_inc
    @indent += STEP
  end

  def indent_dec
    @indent -= STEP
  end

  def indented
    indent_inc
    @nonspace_output_generated << false
    yield

    # Generate pass for empty indent
    unless @nonspace_output_generated.pop
      pass
    end

    indent_dec
  end

  def indent_str
    ' ' * @indent
  end

  def makedirs(path)
    if @fake
      @str << "\nmakedirs #{path}"
    else
      FileUtils.makedirs path
    end
  end

  def method(name, true_method=true, decorators=[], generated_block:nil)
    function name, decorators, generated_block:generated_block do
      argument 'self' if true_method
      yield
    end
  end

  def nl
    # Don't put unnecessary newlines on the beginning of the file.
    write "\n" unless current_file.nil? or current_file.pos == 0
  end

  def open(path)
    if @fake
      @str << "\nOpening #{path}"
      yield path
      @str << "\nClosing #{path}"
    else
      generated_files << path
      FileUtils.makedirs File.dirname(path)
      File.open(path, 'wt') do
        |file|
        yield file
      end
    end
  end

  def open_module(filename)
    full_path = @modules.join('/') + "/#{filename}.py"

    # Reset global naming variables for each file
    $last_block_id = 1
    $if_var_id = 0
    $and_or_var_id = 0

    open(full_path) do
      |file|
      @files << file
      @indent = 0
      comment "Generated file by rb2py, do not edit directly"
      comment "https://github.com/molhanec/rb2py/"
      nl; write 'from copy import copy, deepcopy'
      nl; write 'import rb2py'
      if toplevel_module
        nl; write "import #{toplevel_module}"
      end
      for import in imports
        nl; write "import #{import}"
      end
      yield
      @indent = 0
      @files.pop
    end
  end

  def package(name, &block)
    @modules << name
    full_path = @modules.join('/')
    makedirs full_path
    open_module '__init__', &block
    @modules.pop
  end

  def paren(opening='(', closing=')')
    write opening
    yield
    write closing
  end

  def pass
    indent 'pass'
  end

  def plain_import(name)
    @plain_imports << name
  end

  def rb2py_import(name)
    @rb2py_imports << name
  end

  def statement(stmt)
    @statement_start = true
    stmt.gen
  end

  def symbol(name)
    $pygen.write format_symbol(name)
    symbols << name
  end

  def symbols_export
    if @fake
      write "\n\nsymboly\n"
      for symbol in symbols.to_a.sort
        write "#{format_symbol(symbol)} = Symbol('#{symbol}')\n"
      end
    else
      File.open 'rb2py/symbol.py', 'wt' do |f|
        f.puts "import rb2py"
      end
    end
  end

  def toplevel_module
    @modules[1]
  end

  def until(condition, statements)
    write 'while '
    call('ruby_false', 'rb2py') {
      condition.gen
    }
    write ':'
    indent_inc
    statements.gen
    indent_dec
  end

  def while(condition, statements)
    write 'while '
    call('ruby_true', 'rb2py') {
      condition.gen
    }
    write ':'
    indent_inc
      statements.gen
    indent_dec
  end

  def write(str)
    if @statement_start
      @statement_start = false
      indent
    end
    current_file << str if current_file
    if str =~ /\S/
      @nonspace_output_generated[-1] = true
    end
  end

  def write_imports
    for import in @rb2py_imports
      import = import.gsub '/', '_'
      indent "from rb2py.#{import} import *"
    end
    @rb2py_imports.clear
    for import in @plain_imports
      indent "import #{import}"
    end
    @plain_imports.clear
    for import in $HINTS_IMPORTS_ADD
      indent "import #{import}"
    end
  end
end

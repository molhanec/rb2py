# Some comments are taken from the standard Ruby documentation.

import io
import numbers
import os
import random
import re
import sys
import types
from collections import abc, OrderedDict
from copy import copy
from inspect import isclass
from warnings import warn

import rb2py.Encoding
from rb2py.error import *
from rb2py.exception import Exception
from rb2py.file import File
from rb2py.hash import Hash
from rb2py.string import String
from rb2py.stringio import StringIO
from rb2py.struct import Struct
from rb2py.time import Time

from rb2py import symbolcls

# This servers is_respond_to() function.
# E.g. if object does not have rewind() method, but it has seek() we return True anyway.
TRANSLATED_METHODS = {
    'rewind': 'seek',
}

# Aliases
SEEK_CUR = io.SEEK_CUR
SEEK_END = io.SEEK_END
SEEK_SET = io.SEEK_SET

# Abstract Base Classes

ArrayABC = abc.MutableSequence
HashABC = abc.MutableMapping
NumberABC = numbers.Number


# Globals

env = OrderedDict()
for name, value in os.environ.items():
    env[String(name)] = String(value)

class NoBlock(object):
    def __bool__(self):
        return False
NO_BLOCK = NoBlock()

# Helpers

def s(string):
    return String(string)


def w(msg):
    "Issue a warning"
    print(msg)


# Decorators

def emulated(name):
    """Decorator for emulated methods.
    First tries to see if the target object does not implement the method
    explicitely. If so, it is called.
    Otherwise calls the emulating function.
    """
    def wrap(emulate):
        def try_to_call(*args, **kwargs):
            # first argument is always the original target
            original_target = args[0]
            method = responds_to(original_target, name)
            return method(*args[1:], **kwargs) if method else emulate(*args, **kwargs)
        return try_to_call
    return wrap


def special_implementation(cls, function):
    """Decorator for emulated methods.
       Redirects to an implementation for a particular type.
       Equivalent to
         if isinstance(first_arg, cls): return function(*args)
    """
    def wrap(default_implementation):
        def try_to_call(*args):
            # first argument is always the original target
            original_target = args[0]
            if isinstance(original_target, cls):
                return function(*args)
            else:
                return default_implementation(*args)
        return try_to_call
    return wrap

# Translations
# Name
#   original_nameArgument_count
#   or just the original_name for any number of arguments
# They mostly works like this:
#   if it is known translation then translate otherwise expects that it is normal method

def abs0(integer):
    return abs(integer)


# list << value -> list
def append(collection, value):
    # list
    if isinstance(collection, list):
        collection.append(value)
        return collection
    # standard integer shift
    elif isinstance(collection, int):
        return collection << value
    elif isinstance(collection, str):
        w('String append')
        return collection + value
    elif isinstance(collection, io.IOBase):
        # file-like object
        if isinstance(value, String):
            value.write_to_file(collection)
        elif isinstance(value, int):
            collection.write(str(value).encode('UTF-8'))
        else:
            raise Rb2PyNotImplementedError("rb2py.append(file, {})".format(type(value)))
        return collection
    else:
        return collection.append(value)


# Arity without self.
# Note that
#   class C:
#     def f(self, value):
#   arity0(C.f) --> 2 # self not deducted
#   arity0(C().f) --> 1
def arity0(method):
    arity = method.__code__.co_argcount
    if hasattr(method, '__self__'):
        arity -= 1
    return arity


# Array(object) -> array
def Array1(object):
    try:
        result = to_a0(object)
    except TypeError:
        result = [object]
    return result


def array_detect(block, array):
    return next(filter(block, array), None)


def array_empty(array):
    return not array


def array_first(array):
    return array[0] if len(array) > 0 else None


def array_last(array):
    return array[-1] if len(array) > 0 else None


# Ruby: fun.call() ~ Python: fun()
def call(fun, *args, **kwargs):
    return fun(*args, **kwargs)


#   case left
#     when right
# or
#   left === right
@emulated('case_cmp')
def case_cmp(left, right, regexp_captures=None):
    if isinstance(right, re._pattern_type):
        return left.match(right, regexp_captures) is not None
    return right == left


def chr0(integer):
    return String(chr(integer))


# array.collect(function) -> new_array
# Returns a new array with the results of running function once for every element in enum.
def collect1(array, block):
    if is_symbol(block):
        block = symbol_to_method(block)
    method = responds_to(array, 'collect')
    if method:
        return method(block)
    return list(map(block, array))


# array.compact -> new_ary
# Returns a copy of array with all nil elements removed.
@emulated('compact')
def compact0(array):
    return [item for item in array if item is not None]


# class_or_module.const_get(string_or_symbol) -> value
def const_get1(collection, value):
    return getattr(collection, str(value))


# object.class() -> class
@emulated('class')
def class0(object):
    return object.__class__


# a <=> b
@emulated('_cmp')
def cmp1(a, b):
    if a < b: return -1
    elif a > b: return 1
    else: return 0


# array1.concat(array2) -> array1
# Appends the elements of array2 to self.
@emulated('concat')
def concat1(array1, array2):
    array1 += array2
    return array1


# array.count() -> integer
@emulated('count')
def count0(array):
    return len(array)


# array.count(object) -> integer
# If an argument is given, counts the number of elements which equal obj using ==.
@emulated('count')
def count1(array, object):
    count = 0
    for item in array:
        if object == item:
            count += 1
    return count


def create_regexp(pattern, flags = 0):
    # These two flags apply always in Ruby regexps:
    #   Make \w, \W, \d, \D, \s and \S ASCII only.
    #   ^ and $ match beginning and end of a new line, not only of string.
    flags |= re.ASCII | re.MULTILINE
    if isinstance(pattern, ArrayABC):
        pattern = "".join(str(part) for part in pattern)
    else:
        pattern = str(pattern)
    return re.compile(pattern, flags)


# array.delete(obj) -> item or nil
# Deletes all items from self that are equal to obj.
# Returns the last deleted item, or nil if no matching item is found
def delete1_array(array, object):
    last_deleted = None
    try:
        while True:
            index = array.index(object)
            last_deleted = array[index]
            del array[index]
    except ValueError:
        return last_deleted


# hash.delete(key) -> value
# Deletes the key-value pair and returns the value from hsh whose key is equal to key.
# If the key is not found, returns nil.
def delete1_hash(hash, key):
    try:
        value = hash[key]
        del hash[key]
        return value
    except KeyError:
        # print("Key '{}' not found in a hash '{}'".format(key, hash))
        return None


@emulated('delete')
@special_implementation(ArrayABC, delete1_array)
@special_implementation(HashABC, delete1_hash)
def delete1(container, obj):
    raise Rb2PyNotImplementedError('Delete for container type %s' % type(container))


# ary.delete_if { |item| block } -> ary
# Deletes every element of self for which block evaluates to true.
# The array is changed instantly every time the block is called, not after the iteration is over.
def delete_if0_array(block, array):
    index = 0
    while index < len(array):
        item = array[index]
        if ruby_true(block(item)):
            del array[index]
        else:
            index += 1
    return array


# hsh.delete_if {| key, value | block } -> hsh
# Deletes every key-value pair from hsh for which block evaluates to true.
def delete_if0_hash(block, hash):
    keys_copy = list(hash.keys())
    for key in keys_copy:
        value = hash[key]
        if ruby_true(block(key, value)):
            del hash[key]
    return hash


@emulated('delete_if')
@special_implementation(ArrayABC, delete_if0_array)
@special_implementation(HashABC, delete_if0_hash)
def delete_if0(block, array):
    raise Rb2PyNotImplementedError('DeleteIf for container type %s' % type(container))


# collection.detect { predicate } -> element or None
def detect(block, collection):
    for element in collection:
        value = block(element)
        if ruby_true(value):
            return element
    return None


# left - right
def difference(left, right):
    # handle array difference
    if isinstance(left, list) and isinstance(right, list):
        s = set(right)
        return [value for value in left if value not in s]
    else:
        return left - right


# left / right
def division(left, right):
    if isinstance(left, float) or isinstance(right, float):
        return left / right
    else:
        return left // right


# string.downcase() -> string
# Note that Python's lower() is Unicode aware, while Ruby's downcase()
# converts just ASCII characters.
@emulated('downcase')
def downcase0(string):
    return string.lower()


# Used in for-in loop
def each(object):
    if isinstance(object, dict):
        # For dictionaries return (key, value) tuples
        return object.items()
    else:
        return object


# array.each_index -> Enumerator
# Same as #each, but passes the index of the element instead of the element itself.
@emulated('each_index')
def each_index0(array):
    return list(range(len(array)))


# hash.each_value {| value | block } -> hash
# Calls block once for each key in hash, passing the value as a parameter.
@emulated('each_value')
def each_value0(hash, block):
    # ignore collection.each_value(&:freeze)
    if block != to_sym0('freeze'):
        for value in hash.values():
            block(value)
    return hash
each_value1 = each_value0


# array.each_with_object(obj) { |item, obj| ... } -> obj
# Iterates the given block for each element with an arbitrary object given, and returns the initially given object.
@emulated('each_with_object')
def each_with_object(array, object, block):
    for item in each(array):
        block(item, object)
    return object


# object.extend(module) -> object
def extend1(object, cls):
    for name in dir(cls):
        if name not in ('__class__',
                        '__delattr__',
                        '__dict__',
                        '__dir__',
                        '__doc__',
                        '__getattribute__',
                        '__init__',
                        '__module__',
                        '__new__',
                        '__reduce__',
                        '__reduce_ex__',
                        '__setattr__',
                        '__sizeof__',
                        '__subclasshook__',
                        '__weakref__'):
            attribute = getattr(cls, name)
            if callable(attribute):
                # If it is method, then bind it to the object
                attribute = types.MethodType(attribute, object)
            setattr(object, name, attribute)
    return object


# dict.fetch(index, default) -> value or default
@emulated('fetch')
def fetch2(collection, index, default):
    return get_index(collection, index, default)


# File.exist?(file_name) -> true or false
# Return true if the named file exists.
def file_exist(path):
    result = os.path.exists(str(path))
    return result


# File.foreach(file_name) {|line| block } -> nil
# Executes the block for every line.
def file_foreach(path):
    with open(str(path)) as f:
        for line in f:
            yield String(line)


# array.find { |obj| block } -> obj or nil
# Passes each entry in enum to block. Returns the first for which block is not false.
# If no object matches returns nil.
@emulated('find')
def find(array, block):
    for item in array:
        if ruby_true(block(item)):
            return item
    return None


# collection.first() -> value/nil
@emulated('first')
def first0(collection):
    return collection[0] if collection else None


# list.flatten() -> list
@emulated('flatten')
def flatten0(array):
    result = []
    def real_flatten(array):
        for item in array:
            if isinstance(item, list) or isinstance(item, tuple):
                real_flatten(item)
            else:
                result.append(item)
    real_flatten(array)
    return result


# array.flat_map { |obj| block } -> array
# Returns a new array with the concatenated results of running block once for every element in enum.
@emulated('flat_map')
def flat_map1(array, block):
    array = list(map(block, array))
    return flatten0(array)


def Float1(object):
    return float(object)


# Ignore
@emulated('freeze')
def freeze0(object):
    return object


# collection[index] -> value
def get_index(collection, *args):
    if collection is dict or collection is OrderedDict:
        # Hash[ key, value, ... ] -> new_hash
        # Hash[ [ [key, value], ... ] ] -> new_hash
        # Hash[ object ] -> new_hash
        # Creates a new hash populated with the given objects.
        # Similar to the literal { key => value, ... }. In the first form, keys and values occur in pairs, so there must be an even number of arguments.
        # The second and third form take a single argument which is either an array of key-value pairs or an object convertible to a hash.
        return get_index_create_dict(args)
    if callable(collection):
        # Actually not an index operator but procedure call syntactic sugar.
        # proc[params,...] -> obj
        # Invokes the block, setting the block's parameters to the values in params
        # using something close to method calling semantics. Generates a warning
        # Returns the value of the last expression evaluated in the block.
        return collection(*args)
    if 0 < len(args) <= 2:
        index = args[0]
        if isinstance(index, list):
            index = tuple(index) # in Python list is not hashable, but tuple is
        default = args[1] if len(args) == 2 else None
    else:
        raise Rb2PyException('get_index() expects 2 or 3 arguments, %s given' % len(args))
    try:
        # return collection[index] # Somewhere inside Python cached, so updating __getitem__ does not update [] operator!
        return collection.__getitem__(index)
    except KeyError:
        if isinstance(index, int) and index < 0:
            return get_index(collection, len(collection) + index)
        return default


# Hash[ key, value, ... ] -> new_hash
# Hash[ [ [key, value], ... ] ] -> new_hash
# Hash[ object ] -> new_hash
# Creates a new hash populated with the given objects.
# Similar to the literal { key => value, ... }. In the first form, keys and values occur in pairs,
# so there must be an even number of arguments.
# The second and third form take a single argument which is either an array of key-value pairs
# or an object convertible to a hash.
def get_index_create_dict(args):
    if len(args) == 1:
        return dict(args[0])
    pairs = list((args[i], args[i+1]) for i in range(0, len(args), 2))
    return dict(pairs)


# collection[start, count] -> collection
@emulated('get_indices')
def get_indices(collection, *indices):
    indices_count = len(indices)
    if indices_count == 1:
        index = indices[0]
        return rb2py.get_index(collection, index)
    elif indices_count == 2:
        # String[regexp, capture] special case
        if isinstance(collection, String) and isinstance(indices[0], re._pattern_type):
            return collection.get_indices_regexp(*indices)
        # interpret it as [start, count]
        return collection[indices[0]:indices[0]+indices[1]]
    raise Rb2PyValueError("get_indices() supports only 1 or 2 indices, %d requested" % indices_count)


# string.gsub(pattern {|match| block } -> string
def gsub(string, pattern, block):
    def block_wrapper(match):
        return str(block(match.group()))
    return pattern.sub(block_wrapper, str(string))


# dict.has_key?(key) -> bool
@emulated('has_key')
def has_key1(dict, key):
    return key in dict
is_key1 = has_key1


# Hash.new {|hash, key| block } -> new_hash
# Returns a new, empty hash. If this hash is subsequently accessed by a key that
# doesn't correspond to a hash entry, if a block is specified, it will be called
# with the hash object and the key, and should return the default value.
# It is the block's responsibility to store the value in the hash if required.
def hash_block(block):
    return Hash(block)


@emulated('__hash__')
def hash0(object):
    if isinstance(object, list):
        return hash(tuple(object))
    return hash(object)


# list.index(value) -> int/nil
@emulated('index')
def index1(collection, value):
    if value in collection:
        return collection.index(value)
    return None


# list.insert(index, value) -> list
@emulated('insert')
def insert2(collection, index, value):
    collection.insert(index, value)
    return collection


@emulated('inspect')
def inspect0(object):
    return String(repr(object))


# object.instance_variable_set(name, value) -> value
def instance_variable_set2(object, name, value):
    # @name => _name
    name = name.replace('@', '_', 1)
    setattr(object, name, value)
    return value


# Integer(arg) -> integer
# Converts arg to a Fixnum or Bignum. Numeric types are converted directly
# (with floating point numbers being truncated).
# If arg is a String, when base is omitted or equals zero, radix indicators (0, 0b, and 0x) are honored.
# In any case, strings should be strictly conformed to numeric representation.
# This behavior is different from that of String#to_i.
# Non string values will be converted by first trying to_int, then to_i. Passing nil raises a TypeError.
def Integer(object):
    if object is None:
        raise TypeError('rb2py.Integer() got None')
    if isinstance(object, String):
        object = str(object)
    return int(object)
Integer1 = Integer


# hash.invert() -> new_hash
# Returns a new hash created by using hsh's values as keys, and the keys as values
def invert0(hash):
    return {v: k for k, v in hash.items()}


# collection.any(predicate) -> bool
def is_any(predicate, collection):
    return any(map(predicate, collection))


# collection.any() -> bool
def is_any0(collection):
    return is_any(ruby_true, collection)


# defined? keyword
#
#     defined? @x
# ==>
#     is_defined_instance_var(self, 'x')
#
# In Ruby it returns either a string or None.
# Normally the string value is not used except for debugging, so we simply
# return True instead and only convert False to None.
def is_defined_instance_var(object, variable_name):
    return True if hasattr(object, variable_name) else None


@emulated('is_empty')
def is_empty0(container):
    return len(container) == 0


@emulated('is_even')
def is_even0(integer):
    return integer % 2 == 0


# collection.include?(value) -> bool
def is_include1(collection, value):
    return value in collection


# object.instance_of?(cls) -> bool
def is_instance_of1(object, cls):
    return object.__class__ == cls


def is_string(value):
    return isinstance(value, str) or isinstance(value, String)


def is_symbol(value):
    return isinstance(value, symbolcls.Symbol)


# number.zero? -> bool
@emulated('is_zero')
def is_zero0(number):
    return number == 0


# array.join -> string
@emulated('join')
def join0(array):
    return String('').join(array)


# array.join(separator) -> string
@emulated('join')
def join1(array, separator):
    return separator.join(str(item) for item in array)


# hash.keys() -> array
@emulated('keys')
def keys0(hash):
    return list(hash.keys())


# collection.last() -> value/nil
@emulated('last')
def last0(collection):
    return collection[-1] if collection else None


# object.length() -> int
@emulated('length')
def length0(object):
    return len(object)


# array.new(size, default=nil) -> array
def list_create_from_size_and_default(size, default=None):
    return [default for _ in range(size)]


# collection.map(:symbol_meaning_method) -> array
@emulated('map')
def map1(collection, block):
    # Note that this might be called using keyword argument "block".
    if block == to_sym0('freeze'):
        return shallow_copy(collection) # ignore
    elif block == to_sym0('inspect'):
        return map2(inspect0, collection)
    elif block == to_sym0('to_f'):
        return map2(to_f0, collection)
    raise Rb2PyNotImplementedError("map1 for {!r}".format(block))


# collection.map { block } -> array
@emulated('map')
def map2(block, collection):
    if block == to_sym0('freeze'):
        return shallow_copy(collection)
    return list(map(block, collection))


# map! {|item| block } -> ary
def map_in_place(block, array):
    for i, value in enumerate(array):
        array[i] = block(value)
    return array


# =~ operator
# =~ is Ruby's basic pattern-matching operator. When one operand is a regular expression and the other
# is a string then the regular expression is used as a pattern to match against the string.
# (This operator is equivalently defined by Regexp and String so the order of String and Regexp do not matter.
# Other classes may have different implementations of =~.) If a match is found, the operator returns index
# of first match in string, otherwise it returns nil.
#
# /hay/ =~ 'haystack'   #=> 0
# 'haystack' =~ /hay/   #=> 0
# /a/   =~ 'haystack'   #=> 1
# /u/   =~ 'haystack'   #=> nil
#
# rb2py_regexp_captures is an array where rb2py_regexp_captures[1], rb2py_regexp_captures[2]... corresponds
# to $1, $2... method-local Ruby variables (group captures)
def match(arg1, arg2, rb2py_regexp_captures=None):
    if isinstance(arg1, String):
        return arg1.match(arg2, rb2py_regexp_captures)
    elif isinstance(arg2, String):
        return arg2.match(arg1, rb2py_regexp_captures)
    else:
        Rb2PyNotImplementedError("rb2py.match() requires one rb2py.String argument")


@emulated('max')
def max0(sequence):
    if len(sequence) > 0:
        return max(sequence)
    else:
        return None


# hash1.merge(hash2) -> new_hash
@emulated('merge')
def merge1(hash1, hash2):
    new_hash = copy(hash1)
    new_hash.update(hash2)
    return new_hash


# hash1.merge!(hash2) -> hash1
@emulated('beware_merge')
def beware_merge1(hash1, hash2):
    hash1.update(hash2)
    return hash1


@emulated('min')
def min0(sequence):
    if len(sequence) > 0:
        return min(sequence)
    else:
        return None


# class.name() -> string
@emulated('name')
def name0(cls):
    return String(cls.__qualname__.replace('.', '::'))


# number.nonzero? -> self or nil
# Returns self if num is not zero, nil otherwise.
@emulated('is_nonzero')
def is_nonzero0(number):
    if number == 0:
        return None
    else:
        return number


# object.object_id() -> integer
def object_id0(object):
    return id(object)

@emulated('is_odd')
def is_odd0(integer):
    return integer % 2 != 0


# p(msg1, msg2...) -> msg1, msg2...
# Prints message using inspect/repr instead of to_s/str
@emulated('p')
def p(self, *args):
    print(' '.join(repr(arg) for arg in args))
    return args
    

# sequence.pack(format) -> string
@emulated('pack')
def pack1(sequence, format):
    string = String()
    string.pack(sequence, format)
    return string


# array.partition { |obj| block } -> [ true_array, false_array ]
# Returns two arrays, the first containing the elements of enum for which the block evaluates to true,
# the second containing the rest.
@emulated('partition')
def partition(array, block):
    true_array = []
    false_array = []
    for item in array:
        if block(item):
            true_array.append(item)
        else:
            false_array.append(item)
    return [true_array, false_array]


# list.pop() -> value or None
@emulated('pop')
def pop0(collection):
    return collection.pop() if len(collection) > 0 else None


# stream.pos() -> integer
@emulated('pos')
def pos0(stream):
    return stream.tell()


# array.push(object) -> array
# Append -- Pushes the given object on to the end of this array.
# This expression returns the array itself, so several appends may be chained together.
@emulated('push')
def push1(array, object):
    array.append(object)
    return array


# stream.printf(format_string [, arguments]) -> nil
@emulated('printf')
def printf(stream, format_string, *args):
    string = format_string % args
    append(stream, string)
    
# puts(msg1, msg2...) -> nil
@emulated('puts')
def puts(*args):
    print(' '.join(str(arg) for arg in args))


# rand(max=0) -> number
# If called without an argument, or if max.to_i.abs == 0, rand returns a pseudo-random
# floating point number between 0.0 and 1.0, including 0.0 and excluding 1.0.
# When max.abs is greater than or equal to 1, rand returns a pseudo-random integer
# greater than or equal to 0 and less than max.to_i.abs.
@emulated('rand')
def rand1(max=0):
    max = abs(int(max))
    if max:
        return random.randrange(max)
    else:
        return random.random()


# list.replace(values) -> list
@emulated('replace')
def replace1(array, values):
    array[:] = values
    return array


# Does the object responds to such message?
def responds_to(object, method_name):
    method = getattr(object, method_name, None)
    return method if callable(method) else None


# object.respond_to?(symbol) -> true or false
# object.respond_to?(string) -> true or false
@emulated('is_respond_to')
def is_respond_to1(object, method_name):
    method_name = str(method_name)
    result = responds_to(object, method_name) is not None
    if not(result) and method_name in TRANSLATED_METHODS:
        result = responds_to(object, TRANSLATED_METHODS[method_name])
    return result


# array.reverse -> new_array
# Returns a new array containing self's elements in reverse order.
# Cannot have @emulated('reverse') because list has reverse() method which reverses list in place and returns None.
def reverse0(array):
    return list(reversed(array))


# array.reverse! -> array
# Reverses self in place.
def beware_reverse(array):
    array.reverse()
    return array


# io.rewind -> 0
# Positions ios to the beginning of input
@emulated('rewind')
def rewind0(io):
    io.seek(0)
    return 0


# number.round(ndigits) -> number
@emulated('round')
def round1(number, digits):
    return round(number, digits)


def ruby_false(value):
    return value is None or value is False or value is NO_BLOCK


def ruby_true(value):
    return not ruby_false(value)


def ruby_and(value1, value2):
    return value1 if ruby_false(value1) else value2


def ruby_or(value1, value2):
    return value1 if ruby_true(value1) else value2


# object.send(symbol, arguments) -> value
# Keep in sync with pyfixes/method_rename.rb
@emulated('send')
def send1(object, symbol, *args):
    message_name = str(symbol)
    stripped_name, last_char = message_name[:-1], message_name[-1]
    if last_char == '?':
        if stripped_name.startswith('has_') or stripped_name.startswith('can_'):
            message_name = stripped_name
        else:
            message_name = 'is_' + stripped_name
    elif last_char == '!':
        message_name = 'beware_' + stripped_name
    elif last_char == '=':
        message_name = '_set_' + stripped_name
    return getattr(object, message_name)(*args)


@emulated('set_index')
def set_index(collection, *indices_and_value):
    indices = indices_and_value[:-1] # all but last
    value = indices_and_value[-1]
    if len(indices) == 1:
        index = indices[0]
        if isinstance(index, list): # list is not hashable
            index = tuple(index)
        collection[index] = value
    else:
        raise Rb2PyNotImplementedError('set_index with %s indices' + len(indices))
    return value


def shallow_copy(object):
    return copy(object)


# array.shift -> obj or nil
# Removes the first element of self and returns it (shifting all other elements down by one).
# Returns nil if the array is empty.
def shift_array(array):
    try:
        return array.pop(0)
    except IndexError:
        # empty array
        return None


# hash.shift -> array or obj
# Removes a key-value pair from hash and returns it as the two-item array [ key, value ],
# or the hash's default value if the hash is empty.
def shift_hash(hash):
    try:
        return list(hash.popitem())
    except KeyError:
        # empty hash
        return None


@emulated('shift')
@special_implementation(ArrayABC, shift_array)
@special_implementation(HashABC, shift_hash)
def shift0(object):
    raise Rb2PyNotImplementedError('Shift for container type %s' % type(container))


# list.size() -> len(list)
@emulated('size')
def size0(collection):
    # file-like object
    if isinstance(collection, io.IOBase):
        return collection.tell()
    return len(collection)


# array.sort() -> sorted array
@emulated('sort')
def sort0(array):
    return list(sorted(array))


# # start.step(stop, step) { |i| block }
# # Invokes the given block with the sequence of numbers starting at start,
# # incremented by step (defaulted to 1) on each call.
# # The loop finishes when the value to be passed to the block is greater than limit
# @emulated('step')
# def step3(start, stop, step, block):
#     if not(isinstance(start, int) and isinstance(stop, int) and isinstance(step, int)):
#         raise Rb2PyNotImplementedError("step2 for non-integer values")
#     if start > stop:
#         raise Rb2PyNotImplementedError("step2 start > stop")
#     if step <= 0:
#         raise Rb2PyNotImplementedError("step2 step <= 0")
#     for i in range(start, stop + 1, step):
#         block(i)


# rng.step(step) { |i| block } -> rng
# Iterates over the range, passing each step-th element to the block.
@emulated('step')
def step2(rng, step, block):
    if step <= 0:
        raise Rb2PyNotImplementedError("step2 step <= 0")
    for i in range(rng.start, rng.stop, step):
        block(i)
    return rng


# String(object) -> string
# First tries to call its to_str method, then its to_s method.
def String1(object):
    method = responds_to(object, 'to_str')
    return method() if method else String(object)


def symbol_to_method(symbol):
    if symbol == to_sym0('dup'):
        return shallow_copy
    raise Rb2PyNotImplementedError("Unknown method for symbol {}".format(symbol))

# integer.times -> an_enumerator
# Iterates the given block int times, passing in values from zero to int - 1.
# If no block is given, an Enumerator is returned instead.
@emulated('times')
def times0(integer):
    return list(range(integer))


# object.to_a -> array
@emulated('to_a')
def to_a0(object):
    return list(object)


# object.to_f -> float
def to_f0(object):
    if isinstance(object, str):
        # Ruby allows arbitrary characters after string
        string = object.strip()
        while len(string):
            try:
                return float(string)
            except:
                # make one character shorter
                string = string[:-1]
        # Ruby returns 0.0 when not a float
        return 0.0
    try:
        return float(object)
    except:
        # Ruby returns 0.0 when not a float
        return 0.0


# object.to_i -> integer
def to_i0(object):
    if isinstance(object, str) or isinstance(object, String):
        object = str(object) # convert String to str
        # Ruby allows arbitrary characters after string
        string = object.strip()
        while len(string):
            try:
                return int(string)
            except:
                # make one character shorter
                string = string[:-1]
        # Ruby returns 0.0 when not an integer
        return 0
    try:
        return int(object)
    except:
        # Ruby returns 0 when not an integer
        return 0


# object.to_i(base) -> integer
def to_i1(object, base):
    if isinstance(object, str):
        # Ruby allows arbitrary characters after string
        string = object.strip()
        while len(string):
            try:
                return int(string, base)
            except:
                # make one character shorter
                string = string[:-1]
        # Ruby returns 0.0 when not an integer
        return 0
    try:
        return int(object, base)
    except:
        # Ruby returns 0 when not an integer
        return 0


# object.to_s -> string
@emulated('to_s')
def to_s0(object):
    return String(str(object))


# integer.to_s(base) -> string
def to_s1(integer, base):
    if base == 2:
        format_char = 'b'
    elif base == 8:
        format_char = 'o'
    elif base == 16:
        format_char = 'x'
    else:
        raise Rb2PyValueError('to_s1() can convert only to base 2, 8 or 16. Unsupported base: ' + str(base))
    return String(('{:' + format_char + '}').format(integer))


# symbol.to_sym() -> symbol
# string.to_sym() -> symbol
def to_sym0(object):
    if is_symbol(object):
        return object
    return symbolcls.to_sym(object)


# array.unique -> array
@emulated('unique')
def unique0(array):
    new_array = []
    seen = set()
    for item in array:
        if item not in seen:
            new_array.append(item)
            seen.add(item)
    return new_array


# string.unpack(format) -> sequence
@emulated('unpack')
def unpack1(string, format):
    if isinstance(string, ArrayABC):
        return String.from_byte_list(string).unpack(format)
    raise Rb2PyNotImplementedError('unpack')


# array.unshift(object1, object2...) -> array
# unshift(obj, ...) → ary click to toggle source
# Prepends objects to the front of the array, moving other elements upwards.
def unshift(array, *objects):
    array[0:0] = objects
    return array


# hash1.update(hash2) -> hash1
# @emulated('update')
# Python's dict has "update" method so we cannot use emulated decorator, because it would return None.
def update1(hash1, hash2):
    if isinstance(hash1, dict):
        hash1.update(hash2)
        return hash1
    else:
        return hash1.update(hash2)


# string.upcase() -> string
# Note that Python's upper() is Unicode aware, while Ruby's upcase()
# converts just ASCII characters.
@emulated('upcase')
def upcase0(string):
    return string.upper()


def warn1(msg):
    w(msg)


# array.zip(object) -> new_array
# Unlike Python's zip(), the resulting length is determined by the first argument.
# None is added if second object is shorter.
@emulated('zip')
def zip1(array, object):
    result = []
    for i in range(len(array)):
        result.append([array[i], get_index(object, i)])
    return result

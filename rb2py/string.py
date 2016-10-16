# Custom mutable string class, emulating some of Ruby's method

# Many comments are copied from Ruby's documentation

__all__ = ['String']

import hashlib
import re
from collections import namedtuple
from copy import copy
from functools import total_ordering

import rb2py.pack
from rb2py.error import *
from rb2py.pathname import Pathname
from rb2py.string_succ import succ
from rb2py.symbolcls import Symbol


# Converting to string

StrConvert = namedtuple('StrConvert', 'type convert')
CONVERTERS_TO_STR = (
    StrConvert(Symbol, lambda s: str(s)),
    StrConvert(int, lambda s: str(s)),
    StrConvert(float, lambda s: str(s)),
    StrConvert(Pathname, lambda s: str(s))
)

def convert_to_str(other):
    for converter in CONVERTERS_TO_STR:
        if isinstance(other, converter.type):
            return converter.convert(other)
    raise Rb2PyValueError('Expected str, but {!r} found'.format(type(other)))


# We can use "bytes" as a name
Bytes = bytes


@total_ordering
class String:

    def __init__(self, other=None, *, encoded_str=None, encoding='latin1', bytes=None, hash=None):
        self._encoded_str = encoded_str
        self._encoding = encoding
        self._bytes = bytes
        self._hash = hash
        if other is not None:
            if isinstance(other, String):
                self._encoded_str = copy(other._encoded_str)
                self._encoding = other._encoding
                if self._encoding == "ASCII-8BIT":
                    self._encoding = "latin1"
                self._bytes = copy(other._bytes)
                self._hash = other._hash
            elif isinstance(other, Bytes):
                self._bytes = list(other)
            elif isinstance(other, str):
                self._encoded_str = other
            else:
                self._encoded_str = convert_to_str(other)
        elif encoded_str is None and bytes is None:
            # Empty string
            self._bytes = []

    @staticmethod
    def from_byte_list(byte_list):
        if not isinstance(byte_list, list):
            byte_list = list(byte_list)
        string = String(bytes=byte_list)
        return string

    # Represents the bytes valid string in the current encoding?
    @property
    def _valid(self):
        self._try_to_encode_str()
        return self._encoded_str is not None

    def __add__(self, other):
        if not isinstance(other, String):
            other = String(other)
        other._ensure_bytes()
        result = String(self, encoding=self._encoding)
        result._modify_bytes()
        result._bytes += other._bytes
        return result

    def __eq__(self, other):
        if isinstance(other, String):
            self._ensure_bytes()
            other._ensure_bytes()
            return self._bytes == other._bytes
        else:
            if self._valid:
                # Invalid string cannot ever equal to anything
                return self._encoded_str == other
        return False

    def __getitem__(self, index):
        if self._encoding == 'latin1': # binary string
            self._ensure_bytes()
            return String(bytes=self._bytes.__getitem__(index), encoding=self._encoding)
        if self._valid:
            return String(self._encoded_str.__getitem__(index), encoding=self._encoding)
        else:
            return String(bytes=self._bytes.__getitem__(index), encoding=self._encoding)

    def set_index(self, *args):
        value = args[-1]
        if value.encoding() != self.encoding():
            value = String(value)
            value._set_encoding(self._encoding)
        value._ensure_bytes()
        self._ensure_bytes()
        result = String(bytes=self._bytes, encoding=self._encoding)
        result._modify_bytes()
        arg_count = len(args)
        if arg_count == 2:
            index = args[0]
            result._bytes[index] = value._bytes
        elif arg_count == 3:
            start = args[0]
            stop = start + args[1]
            result._bytes[start:stop] = value._bytes
        else:
            raise Rb2PyValueError("String.set_index() unsupported argument count: {}".format(arg_count))
        return result

    def __hash__(self):
        if self._hash is None:
            self._ensure_bytes()
            self._hash = hash(tuple(self._bytes))
        return self._hash

    def __len__(self):
        if self._valid:
            return len(self._encoded_str)
        else:
            return self.byte_len()

    def __lt__(self, other):
        self._ensure_bytes()
        other._ensure_bytes()
        return self._bytes < other._bytes

    # printf-style formatting
    def __mod__(self, args):
        self._ensure_encoded_str()
        if isinstance(args, list):
            args = tuple(args)
        string = self._encoded_str % args
        return String(string, encoding=self._encoding)

    def __mul__(self, count):
        self._ensure_encoded_str()
        return String(encoded_str=self._encoded_str*count, encoding=self._encoding)

    def __str__(self):
        self._ensure_encoded_str()
        return self._encoded_str

    def __repr__(self):
        self._ensure_encoded_str()
        return repr(self._encoded_str)

    # To an array
    def to_a(self):
        return [self]

    # To String instance
    def to_s(self):
        return self

    # Ensures valid self._bytes array
    def _ensure_bytes(self):
        if self._bytes is None:
            if self._encoded_str:
                try:
                    self._bytes = list(self._encoded_str.encode(str(self._encoding)))
                except UnicodeEncodeError:
                    # Try to switch the encoding
                    if self._encoding == 'latin1': self._encoding = 'UTF-8'
                    else: self._encoding = 'latin1'
                    # elif self._encoding == 'UTF-8': self._encoding = 'latin1'
                    # else: raise Rb2PyNotImplementedError("Unknown encoding {}".format(self._encoding))
                    self._bytes = list(self._encoded_str.encode(str(self._encoding)))
            else:
                self._bytes = []

    def _ensure_encoded_str(self):
        if not self._valid:
            info = bytes(self._bytes).decode('latin1')
            raise Rb2PyRuntimeError('Invalid string {!r}'.format(info))

    def _modify_bytes(self):
        self._ensure_bytes()
        self._encoded_str = None
        self._hash = None

    def _modify_encoded_str(self):
        self._ensure_encoded_str()
        self._bytes = None
        self._hash = None

    def _try_to_encode_str(self):
        if self._encoded_str is None:
            try:
                self._encoded_str = bytes(self._bytes).decode(str(self._encoding))
            except UnicodeDecodeError:
                self._encoded_str = bytes(self._bytes).decode('latin1')

    def append(self, object):
        if isinstance(object, String):
            if self._encoding == 'latin1' or object._encoding == 'latin1':
                object._ensure_bytes()
                self._modify_bytes()
                self._bytes += object._bytes
            else:
                object._ensure_encoded_str()
                self._modify_encoded_str()
                self._encoded_str += object._encoded_str
        elif isinstance(object, str):
            self._modify_encoded_str()
            self._encoded_str += object
        elif isinstance(object, int):
            self._modify_encoded_str()
            self._encoded_str += str(object)
        else:
            raise Rb2PyValueError("Unknown type '%s' for string concatenation." % type(object))
        return self

    concat = append

    def append_byte(self, byte):
        if byte < 0 or byte > 255:
            raise Rb2PyValueError("String.append_byte requires integer > 0 and <= 255, value '{}' found".format(byte))
        self._modify_bytes()
        self._bytes.append(byte)

    def append_char(self, char):
        self._modify_encoded_str()
        self._encoded_str += char

    def binary_substring(self, index, length):
        self._ensure_bytes()
        return String(bytes=self._bytes[index:index + length], encoding=self._encoding)

    def byte_len(self):
        self._ensure_bytes()
        return len(self._bytes)

    # string.chomp(separator=$/) -> new_string
    # Returns a new String with the given record separator removed from the end of str (if present).
    # If $/ has not been changed from the default Ruby record separator,
    # then chomp also removes carriage return characters (that is it will remove \n, \r, and \r\n).
    # If $/ is an empty string, it will remove all trailing newlines from the string.
    def chomp(self):
        self._ensure_encoded_str()
        new_str = self._encoded_str.lstrip("\n\r")
        result = String(new_str, encoding=self._encoding)
        return result

    # string.chop() -> string
    # Returns a new String with the last character removed. If the string ends
    # with \r\n, both characters are removed. Applying chop to an empty string
    # returns an empty string.
    def chop(self):
        result = String(self)
        result.beware_chop()
        return result

    def beware_chop(self):
        if self.is_empty():
            return None
        self._modify_encoded_str()
        if len(self) > 1 and self._encoded_str.endswith("\r\n"):
            self._encoded_str = self._encoded_str[:-2]
        self._encoded_str = self._encoded_str[:-1]
        return self

    def bytes(self):
        self._ensure_bytes()
        return self._bytes
    each_byte = bytes

    def codepoints(self):
        self._ensure_encoded_str()
        return [ord(c) for c in self._encoded_str]
    each_codepoint = codepoints

    # Instantiate String from text which corresponds to Ruby's rules for double quoted strings,
    # which slightly differ from those for Python normal strings.
    # If the string contains \xZY code, it is assumed to be binary.
    # If the string contains \uABCD code, it is assumed to be UTF-8.
    SIMPLE_CHARS = {
        'a': '\a', # bell, ASCII 07h (BEL)
        'b': '\b', # backspace, ASCII 08h (BS)
        'f': '\f', # form feed, ASCII 0Ch (FF)
        't': '\t', # horizontal tab, ASCII 09h (TAB)
        'n': '\n', # newline (line feed), ASCII 0Ah (LF)
        'v': '\v', # vertical tab, ASCII 0Bh (VT)
        'r': '\r', # carriage return, ASCII 0Dh (CR)
        '\\': '\\',# backslash, \
        '"': '"',  # double quote "
        's': ' ',  # space
    }
    HEXCHARS = tuple('0123456789abcdef')
    @staticmethod
    def double_quoted(characters):
        result = String()
        i = 0
        while i < len(characters):
            char = characters[i].lower()
            i += 1
            if char == '\\':
                if i >= len(characters):
                    raise Rb2PyValueError("Double quoted string cannot end with \\ {!r}".format(characters))
                char = characters[i].lower()
                i += 1
                if char in String.SIMPLE_CHARS:
                    result.append_char(String.SIMPLE_CHARS[char])
                elif char == 'x':
                    if i >= len(characters):
                        raise Rb2PyValueError("Invalid hex escape {!r}".format(characters))
                    char = characters[i].lower()
                    i += 1
                    if not char in String.HEXCHARS:
                        raise Rb2PyValueError("Invalid hex escape {!r}".format(characters))
                    if result._encoding != 'latin1':
                        result._set_encoding('latin1')
                    first_nibble = String.HEXCHARS.index(char)
                    if i < len(characters) and characters[i].lower() in String.HEXCHARS:
                        second_nibble = String.HEXCHARS.index(characters[i].lower())
                        i += 1
                        result.append_byte((first_nibble << 4) + second_nibble)
                    else:
                        result.append_byte(first_nibble)
                elif char == 'u':
                    value = 0
                    for _ in range(4):
                        if i >= len(characters):
                            raise Rb2PyValueError("invalid Unicode escape in string {!r}".format(characters))
                        char = characters[i].lower()
                        if not char in String.HEXCHARS:
                            raise Rb2PyValueError("Invalid Unicode escape {!r} in string {!r}".format(char, characters))
                        i += 1
                        value = (value << 4) + String.HEXCHARS.index(char)
                    result.append_char(chr(value))
                else:
                    raise Rb2PyValueError("Unknown escape {!r} in string {!r}".format(char, characters))
            else:
                result.append_char(characters[i-1])
        return result

    def is_empty(self):
        if self._encoded_str is not None:
            return len(self._encoded_str) == 0
        if self._bytes is None:
            return True
        return len(self._bytes) == 0

    def encode(self, encoding):
        string = String(self)
        string._ensure_encoded_str()
        string._encoding = encoding
        string._bytes = None
        string._ensure_bytes()
        return string

    def encoded_substring(self, index, length, encoding):
        self._ensure_bytes()

        # If it is whole string, we don't need to make substring
        if index == 0 and length == len(self._bytes):
            # The encoding corresponds to ours, so we can buffer the conversion
            if encoding is None or encoding == self._encoding:
                self._ensure_encoded_str()
                # return copy
                return String(self)
            string = self
        else:
            string = self.binary_substring(index, length)
        string = String(bytes=string._bytes, encoding=encoding)
        return string

    def encoding(self):
        return self._encoding

    def _set_encoding(self, encoding):
        self._ensure_encoded_str()
        self._bytes = None
        if encoding == "ASCII-8BIT":
            encoding = "latin1"
        self._encoding = encoding
        self._ensure_bytes()

    def first(self):
        return self

    def force_encoding(self, encoding):
        if encoding == "ASCII-8BIT":
            encoding = "latin1"
        self._encoding = encoding
        if self._bytes is None:
            self._bytes = [ord(char) for char in self._encoded_str]
        self._encoded_str = None
        self._hash = None
        return self

    # str[regexp, capture] -> new_str or nil
    # If a Regexp is supplied, the matching portion of the string is returned.
    # If a capture follows the regular expression, which may be a capture group index or name,
    # follows the regular expression that component of the MatchData is returned instead.
    # Returns nil if the regular expression does not match.
    def get_indices_regexp(self, regexp, capture):
        captures = []
        if self.match(regexp, captures):
            return captures[capture]
        else:
            return None

    # Global substitution
    # gsub(pattern, replacement) -> new_str
    def gsub(self, pattern, replacement):
        self._ensure_encoded_str()
        if isinstance(pattern, String):
            string = self._encoded_str.replace(str(pattern), str(replacement))
        else:
            string = pattern.sub(str(replacement), self._encoded_str)
        return String(encoded_str=string, encoding=self._encoding)

    def hexdigest(self, algorithm_name):
        h = hashlib.new(algorithm_name)
        self._ensure_bytes()
        h.update(bytes(self._bytes))
        return h.hexdigest()

    def is_ascii_only(self):
        self._ensure_encoded_str()
        for char in self._encoded_str:
            if ord(char) > 127:
                return False
        return True

    def join(self, array):
        self._ensure_encoded_str()
        result = self._encoded_str.join(str(item) for item in array)
        return String(result, encoding=self._encoding)

    def lower(self):
        self._ensure_encoded_str()
        result = String(encoding=self._encoding)
        for char in self._encoded_str:
            if 'A' <= char <= 'Z':
                result.append_char(chr(ord(char) - ord('A') + ord('a')))
            else:
                result.append_char(char)
        return result

    def upper(self):
        self._ensure_encoded_str()
        result = String(encoding=self._encoding)
        for char in self._encoded_str:
            if 'a' <= char <= 'z':
                result.append_char(chr(ord(char) - ord('a') + ord('A')))
            else:
                result.append_char(char)
        return result

    # =~ operator
    # =~ is Ruby's basic pattern-matching operator. When one operand is a regular expression and the other
    # is a string then the regular expression is used as a pattern to match against the string.
    # If a match is found, the operator returns index of first match in string, otherwise it returns nil.
    #
    # /hay/ =~ 'haystack'   #=> 0
    # 'haystack' =~ /hay/   #=> 0
    # /a/   =~ 'haystack'   #=> 1
    # /u/   =~ 'haystack'   #=> nil
    #
    # rb2py_regexp_captures is an array where rb2py_regexp_captures[1], rb2py_regexp_captures[2]... corresponds
    # to $1, $2... method-local Ruby variables (group captures)
    def match(self, regexp, regexp_captures=None):
        self._ensure_encoded_str()
        if regexp_captures is not None:
            regexp_captures.clear()
        match_object = regexp.search(self._encoded_str)
        if match_object:
            if regexp_captures is not None:
                # $0 in Ruby is script name, not regexp capture
                # We just add emptry String for simplicity
                regexp_captures.append(String(encoding=self._encoding))
                regexp_captures.extend(String(group, encoding=self._encoding) for group in match_object.groups())
            return match_object.start()
        else:
            return None

    # scan(pattern) -> array
    # scan(pattern) {|match, ...| block } -> str
    # Both forms iterate through str, matching the pattern (which may be a Regexp or a String).
    # For each match, a result is generated and either added to the result array or passed to the block.
    # If the pattern contains no groups, each individual result consists of the matched string, $&.
    # If the pattern contains groups, each individual result is itself an array containing one entry per group.
    def scan(self, regexp, block=None):
        self._ensure_encoded_str()
        matches = regexp.findall(self._encoded_str)
        if len(matches):
            if regexp.groups == 1:
                # In Ruby, group in regexp always generates array, even with single object.
                # In Python only multiple groups generate tuple.
                # E.g.
                #   re.findall('.', 'abc') ==  ['a', 'b', 'c'] == re.findall('(.)', 'abc')
                # but
                #   'abc'.scan(/./) == ["a", "b", "c"]
                #   'abc'.scan(/(.)/) == [["a"], ["b"], ["c"]]
                matches = [[String(match, encoding=self._encoding)] for match in matches]
            elif regexp.groups > 1:
                # Convert tuples to lists
                matches = [list([String(group, encoding=self._encoding) for group in match]) for match in matches]
            else:
                # Pattern without groups. Just convert it to String instances
                matches = [String(match, encoding=self._encoding) for match in matches]
        if block:
            for match in matches:
                block(match)
            # The block form returns the original string
            return self
        else:
            return matches

    def slice(self, object, extra=None):
        if isinstance(object, int):
            self._ensure_encoded_str()
            if extra is not None:
                if not isinstance(extra, int):
                    raise Rb2PyValueError("String.slice(index, length) length is not and int!")
                extra += extra + 1
                if extra > len(self._encoded_str):
                    extra = len(self._encoded_str)
            else:
                extra = len(self._encoded_str)
            return self.slice_range(range(object, extra))
        if isinstance(object, range):
            if extra:
                raise Rb2PyValueError("Extra parameter for String.slice(range)")
            return self.slice_range(object)
        if isinstance(object, re._pattern_type):
            if extra:
                raise Rb2PyNotImplementedError("String.slice does not implement capture parameter for regexp")
            return self.slice_regexp(object)
        raise Rb2PyNotImplementedError("Slice for parameter of type '{}'".format(type(object)))

    # slice(range) -> new_str or nil
    # If passed a range, its beginning and end are interpreted as offsets delimiting the substring to be returned.
    # NOT IMPLEMENTED: Returns nil if the initial index falls outside the string or the length is negative.
    def slice_range(self, range):
        self._ensure_encoded_str()
        return String(self._encoded_str[range.start:range.stop:range.step], encoding=self._encoding)

    # slice(regexp) -> new_str or nil
    # If a Regexp is supplied, the matching portion of the string is returned.
    def slice_regexp(self, regexp):
        self._ensure_encoded_str()
        match = regexp.search(self._encoded_str)
        if match:
            return String(match.group(), encoding=self._encoding)
        return None

    def split(self, regexp=None):
        self._ensure_encoded_str()
        s = self._encoded_str

        # Ruby docs: If pattern is omitted, the value of $; is used.
        # If $; is nil (which is the default), str is split on whitespace
        if regexp is None:
            result = s.split()

        # Not really a regexp, just plain string
        elif String.is_string(regexp):
            # Ruby special case
            if regexp == ' ':
                result = s.split()
            else:
                result = s.split(str(regexp))

        # Fix for Python split() regexp bug. See:
        # https://docs.python.org/3/library/re.html#re.split
        elif regexp.pattern == '':
            result = [char for char in s]
        else:
            # Finally standard regexp split() :)
            result = regexp.split(s)

        # Ruby docs: If the limit parameter is omitted, trailing null fields are suppressed.
        # Ruby C code:
        #   if (NIL_P(limit) && lim == 0) {
        #     long len;
        #     while ((len = RARRAY_LEN(result)) > 0 && (tmp = RARRAY_AREF(result, len-1), RSTRING_LEN(tmp) == 0))
        #       rb_ary_pop(result);
        #   }
        while len(result) > 0 and result[-1] == '':
            result.pop()

        return [String(chunk, encoding=self._encoding) for chunk in result]

    def is_start_with(self, other):
        self._ensure_encoded_str()
        return self._encoded_str.startswith(str(other))

    @staticmethod
    def is_string(object):
        return isinstance(object, str) or isinstance(object, String)

    def strip(self):
        self._ensure_encoded_str()
        return String(self._encoded_str.strip(), encoding=self._encoding)

    # lstrip! -> self or nil
    # Removes leading whitespace from str, returning nil if no change was made.
    def beware_lstrip(self):
        self._ensure_encoded_str()
        stripped = self._encoded_str.lstrip()
        if stripped == self._encoded_str:
            # No change
            return None
        else:
            self._encoded_str = stripped
            return self

    def rstrip(self):
        self._ensure_encoded_str()
        return String(self._encoded_str.rstrip(), encoding=self._encoding)

    #  Returns the successor to <i>str</i>. The successor is calculated by
    #  incrementing characters starting from the rightmost alphanumeric (or
    #  the rightmost character if there are no alphanumerics) in the
    #  string. Incrementing a digit always results in another digit, and
    #  incrementing a letter results in another letter of the same case.
    #  Incrementing nonalphanumerics uses the underlying character set's
    #  collating sequence.
    #
    #  If the increment generates a ``carry,'' the character to the left of
    #  it is incremented. This process repeats until there is no carry,
    #  adding an additional character if necessary.
    #
    #     "abcd".succ        #=> "abce"
    #     "THX1138".succ     #=> "THX1139"
    #     "<<koala>>".succ   #=> "<<koalb>>"
    #     "1999zzz".succ     #=> "2000aaa"
    #     "ZZZ9999".succ     #=> "AAAA0000"
    #     "***".succ         #=> "**+"
    def beware_succ(self):
        self._modify_encoded_str()
        self._encoded_str = succ(self._encoded_str)

    def pack(self, array, format):
        format = str(format)
        self._ensure_bytes()

        formats = []
        count = None
        for format_char in format:
            if format_char.isspace():
                continue
            if format_char.isalpha():
                if count:
                    formats[-1].count = count
                    count = None
                formats.append(rb2py.pack.get_packer(format_char))
            elif format_char.isdigit():
                if count:
                    count = count * 10 + int(format_char)
                else:
                    count = int(format_char)
            elif format_char == '*':
                if count:
                    Rb2PyValueError('Unrecognized format "%s"' % format)
                count = '*'
            else:
                raise Rb2PyValueError('Unrecognized format "%s"' % format)
        if count:
            formats[-1].count = count

        index = 0
        for format in formats:
            elements = array[index:]
            format.pack(elements, self)
            index += format.total_count

        return self

    def unpack(self, format):
        format = str(format)
        self._ensure_bytes()

        formats = []
        count = None
        for format_char in format:
            if format_char.isspace():
                continue
            if format_char.isalpha():
                if count is not None:
                    formats[-1].count = count
                    count = None
                formats.append(rb2py.pack.get_packer(format_char))
            elif format_char.isdigit():
                if count:
                    count = count * 10 + int(format_char)
                else:
                    count = int(format_char)
            elif format_char == '*':
                if count:
                    Rb2PyValueError('Unrecognized format "%s"' % format)
                count = '*'
            else:
                raise Rb2PyValueError('Unrecognized format "%s"' % format)
        if count is not None:
            formats[-1].count = count

        index = 0
        result = []
        for packer in formats:
            packer.unpack(self._bytes[index:], result)
            index += packer.total_byte_size

        return result

    def replace(self, other):
        if not isinstance(other, String):
            raise Rb2PyNotImplementedError("String.replace")
        other._ensure_bytes()
        self._modify_bytes()
        self._bytes = other._bytes
        self._encoding = other._encoding
        return self

    def write_to_file(self, file):
        self._ensure_bytes()
        file.write(bytes(self._bytes))

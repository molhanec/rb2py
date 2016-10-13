from argparse import _ActionsContainer
from itertools import count

__all__ = ['get_packer']

from rb2py.error import *
import rb2py

PACKERS = {}

def get_packer(format_char):
    return PACKERS[format_char]()

class Packer:

    def __init__(self, format_char, byte_size):
        self.format_char = format_char
        self.byte_size = byte_size
        self.count = 1
        self.total_byte_size = None

    def pack(self, array, result):
        raise Rb2PyNotImplementedError(type(self))

    def unpack_single(self, bytes):
        raise Rb2PyNotImplementedError(type(self))

    def unpack(self, bytes, result):
        if self.count == '*':
            self.total_byte_size = len(bytes)
            # Make sure that total_byte_size is multiply of byte_size
            self.total_byte_size -= self.total_byte_size % self.byte_size
        else:
            self.total_byte_size = self.count * self.byte_size
        for i in range(0, self.total_byte_size, self.byte_size):
            result.append(self.unpack_single(bytes[i:i+self.byte_size]))


class Packer_a(Packer):
    " a         | String  | arbitrary binary string"

    def __init__(self):
        super().__init__('a', 1)

    def unpack_single(self, bytes):
        return chr(bytes[0])

    def unpack(self, bytes, result):
        if self.count == '*':
            self.total_byte_size = len(bytes)
        else:
            self.total_byte_size = min(self.count, len(bytes))
        string = rb2py.String()
        for i in range(0, self.total_byte_size, self.byte_size):
            string.append_byte(bytes[i])
        result.append(string)

PACKERS['a'] = Packer_a


class Packer_A(Packer):
    """
    A         | String  | pack: arbitrary binary string (space padded, count is width)
    A         | String  | unpack: arbitrary binary string (remove trailing nulls and ASCII spaces)"""

    def __init__(self):
        super().__init__('A', 1)

    def pack(self, array, result):
        string = rb2py.String(array[0])
        self.total_count = 1
        string._ensure_bytes()
        if self.count == '*':
            total_count = len(string)
        else:
            total_count = min(self.count, len(string))
        for i in range(total_count):
            result.append_byte(string._bytes[i])
        if self.count != "*":
            for i in range(self.count - total_count):
                result.append_byte(ord(" "))

    def unpack_single(self, bytes):
        return chr(bytes[0])

    def unpack(self, bytes, result):
        if self.count == '*':
            self.total_byte_size = len(bytes)
        else:
            self.total_byte_size = min(self.count, len(bytes))
        string = rb2py.String()
        last_non_null = 0
        for i in range(0, self.total_byte_size, self.byte_size):
            byte = bytes[i]
            if byte not in (0, ord(' ')):
                last_non_null = i
        for i in range(last_non_null + 1):
            string.append_byte(bytes[i])
        result.append(string)

PACKERS['A'] = Packer_A


class Packer_c(Packer):
    " c         | Integer | 8-bit signed (signed char)"

    def __init__(self):
        super().__init__('c', 1)

    def pack(self, array, result):
        if self.count == '*':
            self.total_count = len(array)
        else:
            self.total_count = min(self.count, len(array))
        for i in range(self.total_count):
            byte = array[i]
            if byte < 0:
                byte += 256
            result.append_byte(byte)

    def unpack_single(self, bytes):
        byte = bytes[0]
        if byte > 127:
            byte -= 256
        return byte

PACKERS['c'] = Packer_c


class Packer_C(Packer_c):
    " C         | Integer | 8-bit unsigned (unsigned char)"

    def __init__(self):
        super().__init__()
        self.format_char = 'C'

    def unpack_single(self, bytes):
        return bytes[0]

PACKERS['C'] = Packer_C


class Packer_H(Packer):
    " H         | String  | hex string (high nibble first)"

    def __init__(self):
        super().__init__('H', 1)

    def unpack_single(self, byte):
        return '{:02x}'.format(byte)

    # Each byte contains two nibbles
    def unpack(self, bytes, result):
        if self.count == '*':
            self.total_byte_size = len(bytes)
            nibble_count = self.total_byte_size * 2
        else:
            self.total_byte_size = min((self.count + 1) // 2, len(bytes))
            nibble_count = self.count
        string = rb2py.String()
        i = 0
        while nibble_count > 0 and i < len(bytes):
            byte = bytes[i]
            two_nibbles = self.unpack_single(byte)
            if nibble_count == 1:
                string.append(two_nibbles[0])
            else:
                string.append(two_nibbles)
            i += 1
            nibble_count -= 2
        result.append(string)

PACKERS['H'] = Packer_H


class Packer_q(Packer):
    " q         | Integer | 64-bit signed, native endian (int64_t)"

    def __init__(self):
        super().__init__('q', 8)

    def unpack_single(self, bytes):
        a, b, c, d, e, f, g, h = bytes
        # result = (a << 56) + (b << 48) + (c << 40) + (d << 32) + (e << 24) + (f << 16) + (g << 8) + h
        result = (h << 56) + (g << 48) + (f << 40) + (e << 32) + (d << 24) + (c << 16) + (b << 8) + a
        if h > 127:
            result = -1 * (2 ** 64 - result)
        return result

PACKERS['q'] = Packer_q


class Packer_n(Packer):
    " n         | Integer | 16-bit unsigned, network (big-endian) byte order"

    def __init__(self):
        super().__init__('n', 2)

    def pack(self, array, result):
        if self.count == '*':
            self.total_count = len(array)
        else:
            self.total_count = min(self.count, len(array))
        for i in range(self.total_count):
            integer = array[i]
            if integer < 0:
                integer += 2**16
            if not(0 <= integer < 2**16):
                raise Rb2PyValueError("array.pack('n'): '{}' is not a 16-bit unsigned number!".format(integer))
            a, b = divmod(integer, 256)
            result.append_byte(a)
            result.append_byte(b)

    def unpack_single(self, bytes):
        a, b = bytes
        return (a << 8) + b

PACKERS['n'] = Packer_n


class Packer_N(Packer):
    " N         | Integer | 32-bit unsigned, network (big-endian) byte order"

    def __init__(self):
        super().__init__('N', 4)

    def pack(self, array, result):
        if self.count == '*':
            self.total_count = len(array)
        else:
            self.total_count = min(self.count, len(array))
        for i in range(self.total_count):
            integer = array[i]
            if integer < 0:
                integer += 2**32
            if not(0 <= integer < 2**32):
                raise Rb2PyValueError("array.pack('n'): '{}' is not a 32-bit unsigned number!".format(integer))
            a, integer = divmod(integer, 2**24)
            b, integer = divmod(integer, 2**16)
            c, d = divmod(integer, 2**8)
            result.append_byte(a)
            result.append_byte(b)
            result.append_byte(c)
            result.append_byte(d)

    def unpack_single(self, bytes):
        a, b, c, d = bytes
        return  (a << 24) + (b << 16) + (c << 8) + d

PACKERS['N'] = Packer_N


class Packer_U(Packer):
    " U         | Integer | UTF-8 character"

    def __init__(self):
        super().__init__('U', 1)

    def pack(self, array, result):
        for i in range(self.count):
            b = bytes(chr(array[i]), 'utf-8')
            for byte in b:
                result.append_byte(byte)
        self.total_count = self.count

    def unpack_single(self, bytes):
        raise Rb2PyNotImplementedError()
    #     return chr(bytes[0])

    def unpack(self, b, result):
        self.total_byte_size = 0
        actual_count = 0
        # max_count can be >= len(b)
        max_count = len(b) if self.count == '*' else self.count
        utf8_char_start = 0
        while actual_count < max_count and utf8_char_start < len(b):
            first_byte = b[utf8_char_start]
            byte_count = 0
            while first_byte & 0b10000000:
                byte_count += 1
                first_byte <<= 1
            if byte_count == 0: byte_count = 1
            utf8_char_end = utf8_char_start + byte_count
            if utf8_char_end > len(b):
                raise Rb2PyValueError("Invalid UTF-8 byte sequence")
            bytes_for_one_char = bytes(b[utf8_char_start:utf8_char_end])
            utf8_char_start = utf8_char_end
            actual_count += 1
            result.append(ord(bytes_for_one_char.decode('UTF-8')))
        self.total_byte_size = utf8_char_start

PACKERS['U'] = Packer_U


class Packer_x(Packer):
    " x         | ---     | skip forward one byte"

    def __init__(self):
        super().__init__('x', 1)

    def unpack_single(self, bytes):
        pass

    def unpack(self, bytes, result):
        self.total_byte_size = self.count

PACKERS['x'] = Packer_x


class Packer_Z(Packer):
    " Z         | String  | null-terminated string"

    def __init__(self):
        super().__init__('Z', 1)

    def unpack_single(self, bytes):
        return chr(bytes[0])

    def unpack(self, bytes, result):
        if self.count == '*':
            self.total_byte_size = len(bytes)
        else:
            self.total_byte_size = min(self.count, len(bytes))
        string = rb2py.String()
        for i in range(self.total_byte_size):
            byte = bytes[i]
            if byte == 0:
                self.total_byte_size = i + 1
                break
            string.append_byte(byte)
        result.append(string)

PACKERS['Z'] = Packer_Z

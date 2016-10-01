__all__ = ['StringIO']

import io
import rb2py.string
from rb2py.error import *


class StringIO:
    
    def __init__(self, string=rb2py.String()):
        self._string = string
        self.index = 0

    def __len__(self):
        return len(self._string)

    def set_encoding(self, encoding):
        self._string._set_encoding(encoding)
        
    @property
    def _pos(self):
        return self.index

    @_pos.setter
    def _pos(self, value):
        self.index = value
    _pos_setter = _pos

    def _set_pos(self, value):
        self._pos = value

    def append(self, string):
        self._string.append(string)
        return self

    def binmode(self):
        self._string.force_encoding('latin1')

    def read(self, length=None):
        """
        Reads length bytes from the I/O stream.

        length must be a non-negative integer or nil.

        If length is a positive integer, it tries to read length bytes
        without any conversion (binary mode). It returns nil or a string
        whose length is 1 to length bytes. nil means it met EOF at beginning.
        The 1 to length-1 bytes string means it met EOF after reading the result.
        The length bytes string means it doesn't meet EOF.
        The resulted string is always ASCII-8BIT encoding.

        If length is omitted or is nil, it reads until EOF and the encoding
        conversion is applied. It returns a string even if EOF is met at beginning.

        If length is zero, it returns "".

        At end of file, it returns nil or "" depend on length.
        ios.read() and ios.read(nil) returns "".
        ios.read(positive-integer) returns nil
        """
        if length is None:
            length = self._string.byte_len()
            result = self._string.encoded_substring(self.index, length, self.encoding)
            self.index += length

        elif length == 0:
            result = rb2py.string.String()

        elif length > 0:
            result = self._string.binary_substring(self.index, length)
            self.index += length

        return result

    def seek(self, position, whence=io.SEEK_SET):
        if whence == io.SEEK_SET:
            self.index = position
        elif whence == io.SEEK_CUR:
            self.index += position
        elif whence == io.SEEK_END:
            self.index = len(self._string) + position
        else:
            raise Rb2PyValueError("Unsupported rb2py.StringIO.seek() whence value '{}'".format(whence))

    def string(self):
        return self._string

    def tell(self):
        return self.index

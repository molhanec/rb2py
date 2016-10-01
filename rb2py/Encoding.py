from rb2py.error import *

# Assign appropriate names corresponding to codecs module

ASCII_8BIT = 'latin1'
US_ASCII = 'ascii'
UTF_16BE = 'utf_16_be'
UTF_8 = 'utf_8'
WINDOWS_1252 = 'cp1252'

class InvalidByteSequenceError(Rb2PyRuntimeError):
    pass


class UndefinedConversionError(Rb2PyRuntimeError):
    pass
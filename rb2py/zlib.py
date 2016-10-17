from rb2py import String
from rb2py.error import *

import zlib

class Zlib:

    class Deflate:
        @staticmethod
        def deflate(stream):
            # if not isinstance(stream, str):
            #     stream = str(stream)
            if not isinstance(stream, String):
                raise Rb2PyNotImplementedError()
            stream._ensure_bytes()
            return zlib.compress(bytes(stream._bytes))

    # class Inflate:
    #     @staticmethod
    #     def inflate(stream):
    #         return zlib.decompress(stream).decode('UTF-8')
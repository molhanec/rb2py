import zlib

class Zlib:

    class Deflate:
        @staticmethod
        def deflate(stream):
            if not isinstance(stream, str):
                stream = str(stream)
            return zlib.compress(bytes(stream, 'UTF-8'))

    class Inflate:
        @staticmethod
        def inflate(stream):
            return zlib.decompress(stream).decode('UTF-8')

__all__ = ['Digest']

class Digest:
    class MD5:
        @staticmethod
        def hexdigest(content):
            return content.hexdigest('md5')

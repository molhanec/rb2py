
__all__ = ['Digest']

class Digest:
    class SHA1:
        @staticmethod
        def hexdigest(content):
            return content.hexdigest('sha1')

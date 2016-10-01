
import rb2py

__all__ = ['File']


class File:

    def __init__(self, *, opened_file=None, binary):
        self.file = opened_file
        self.binary = binary

    def close(self):
        if self.file:
            self.file.close

    def read(self):
        return rb2py.String(self.file.read(), encoding=('latin1' if self.binary else 'UTF-8'))
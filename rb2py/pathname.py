# class Pathname
#
# Pathname represents the name of a file or directory on the filesystem, but not the file itself.
#
# A Pathname can be relative or absolute. It's not until you try to reference the file that it
# even matters whether the file exists or not.
#
# Pathname is immutable. It has no method for destructive update.

__all__ = ['Pathname']

import pathlib
import rb2py

class Pathname:

    def __init__(self, path):
        self.path = pathlib.Path(str(path))

    def is_file(self):
        """
        Returns true if the named file exists and is a regular file.
        If the file argument is a symbolic link, it will resolve
        the symbolic link and use the file referenced by the link.
        """
        return self.path.is_file()

    def open(self, mode):
        return rb2py.File(opened_file=self.path.open(mode=mode), binary=("b" in mode))

    def __str__(self):
        return str(self.path)




from datetime import datetime
import tzlocal

import rb2py

_local_timezone = tzlocal.get_localzone()

class Time:
    def __init__(self):
        self.datetime = datetime.now(_local_timezone)
    def __str__(self):
        return repr(self)
    def __repr__(self):
        return self.strftime("%Y-%m-%d %H:%M:%S %z")
    def strftime(self, format):
        return rb2py.String(self.datetime.strftime(str(format)))

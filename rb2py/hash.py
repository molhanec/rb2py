import collections

_NotSpecified = object()

class Hash:

    def __init__(self, default_value=None):
        self.d = collections.OrderedDict()
        self.default_value = default_value

    def __len__(self):
        return len(self.d)

    def __getitem__(self, key):
        if key in self.d:
            return self.d[key]
        if callable(self.default_value):
            return self.default_value(self, key)
        return self.default_value

    def __setitem__(self, key, value):
        self.d[key] = value

    def __delitem__(self, key):
        del self.d[key]

    def __contains__(self, key):
        return key in self.d
#
    def __iter__(self):
        return iter(self.d)

    def clear(self):
        return self.d.clear()

    def copy(self):
        new_hash = Hash()
        new_hash.d = self.d.copy()
        new_hash.default_value = self.default_value
        return new_hash

    def is_empty(self):
        return len(self.d) == 0

    @staticmethod
    def fromkeys(seq, value=None):
        new_hash = Hash()
        new_hash.d = dict.fromkeys(seq, value)
        return new_hash

    def get(self, key, default=_NotSpecified):
        if default is _NotSpecified:
            return self[key]
        else:
            return self.d.get(key, default)

    def items(self):
        return self.d.items()

    def keys(self):
        return self.d.keys()

    def pop(self, key, default=_NotSpecified):
        if default is _NotSpecified:
            return self.d.pop(key)
        else:
            return self.d.pop(key, default)

    def popitem(self):
        return self.d.popitem()

    def setdefault(self, key, default):
        return self.d.setdefault(key, default)

    def shift(self):
        if self.is_empty():
            return self.default_value
        else:
            return list(self.d.popitem())

    def update(self, *args):
        return self.d.update(*args)

    def values(self):
        return self.values()

    def __eq__(self, other):
        return self.d == other.d

    def __lt__(self, other):
        return self.d < other.d

    def __le__(self, other):
        return self.d <= other.d

    def __gt__(self, other):
        return self.d > other.d

    def __ge__(self, other):
        return self.d >= other.d



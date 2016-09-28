# Custom class to represents symbols

# List of known symbols
rb2py_symbols = {}


# Single symbol
class Symbol:
    
    def __init__(self, name):
        global rb2py_symbols
        self.name = str(name)
        rb2py_symbols[self.name] = self
        
    def __repr__(self):
        return "Symbol(%s)" % self.name

    def __str__(self):
        return self.name


# Converts string (or anything convertable to string) to symbol.
# If it is a known symbol returns already created object, so if you always use this method there won't be
# never two different symbol object with the same name. Notice, that Symbol class does not implement __eq__()
# or __hash__() so it relies on this property.
# For custom code use rb2py.to_sym0()
def to_sym(name):
    name = str(name)
    if name not in rb2py_symbols:
        Symbol(name) # adds to rb2py_symbols in constructor
    return rb2py_symbols[name]
    
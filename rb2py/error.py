
class Rb2PyError:
    "Custom marker for thrown exceptions"
    pass

class Rb2PyException(Exception, Rb2PyError): pass

class Rb2PyNotImplementedError(NotImplementedError, Rb2PyError): pass

class Rb2PyRuntimeError(RuntimeError, Rb2PyError): pass

class Rb2PyValueError(ValueError, Rb2PyError): pass


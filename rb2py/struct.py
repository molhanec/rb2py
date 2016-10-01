# Code based on the collections module of Python 3.5.1

from keyword import iskeyword as _iskeyword
import sys as _sys

_class_template = """\
class {typename}:

    def __init__(self, {arg_list}):
{fields_setup}

    def __repr__(self):
        return self.__class__.__name__ + '({repr_fmt})' % self

{getters}
"""

_repr_template = '{name}=%r'

_argument_template = '{name}=None'

_field_setup_template = '''\
        self.{name} = {name}
'''

_getter_template = '''\
    def {name}(self):
        return self._{name}
'''

def Struct(typename, *field_names, verbose=False, rename=False):
    # Validate the field names.  At the user's option, either generate an error
    # message or automatically replace the field name with a valid name.
    if isinstance(field_names, str):
        field_names = field_names.replace(',', ' ').split()
    field_names = list(map(str, field_names))
    typename = str(typename)
    if rename:
        seen = set()
        for index, name in enumerate(field_names):
            if (not name.isidentifier()
                or _iskeyword(name)
                or name.startswith('_')
                or name in seen):
                field_names[index] = '_%d' % index
            seen.add(name)
    for name in [typename] + field_names:
        if type(name) != str:
            raise TypeError('Type names and field names must be strings')
        if not name.isidentifier():
            raise ValueError('Type names and field names must be valid '
                             'identifiers: %r' % name)
        if _iskeyword(name):
            raise ValueError('Type names and field names cannot be a '
                             'keyword: %r' % name)
    seen = set()
    for name in field_names:
        if name.startswith('_') and not rename:
            raise ValueError('Field names cannot start with an underscore: '
                             '%r' % name)
        if name in seen:
            raise ValueError('Encountered duplicate field name: %r' % name)
        seen.add(name)

    # Fill-in the class template
    class_definition = _class_template.format(
        typename = typename,
        field_names = tuple(field_names),
        num_fields = len(field_names),
        arg_list = ', '.join(_argument_template.format(name=name) for name in field_names),
        repr_fmt = ', '.join(_repr_template.format(name=name) for name in field_names),
        fields_setup = ''.join(_field_setup_template.format(name=name) for name in field_names),
        getters = '\n'.join(_getter_template.format(name=name) for name in field_names)
    )
    if verbose:
        print(class_definition)

    # Execute the template string in a temporary namespace and support
    # tracing utilities by setting a value for frame.f_globals['__name__']
    namespace = dict(__name__='Struct_%s' % typename)
    exec(class_definition, namespace)
    result = namespace[typename]
    result._source = class_definition
    if verbose:
        print(result._source)

    # For pickling to work, the __module__ variable needs to be set to the frame
    # where the named tuple is created.  Bypass this step in environments where
    # sys._getframe is not defined (Jython for example) or sys._getframe is not
    # defined for arguments greater than 0 (IronPython).
    try:
        result.__module__ = _sys._getframe(1).f_globals.get('__name__', '__main__')
    except (AttributeError, ValueError):
        pass

    return result

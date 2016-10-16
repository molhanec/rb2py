__all__ = ["succ"]

from rb2py.error import *

# https://github.com/huandu/xstrings/blob/master/convert.go#L291
# https://www.snip2code.com/Snippet/957453/Python-implementation-of-Ruby-String-suc
# http://stackoverflow.com/questions/20721214/pythons-counterpart-for-ruby-stringsucc

# /*
# *  call-seq:
# *     str.succ   -> new_str
# *     str.next   -> new_str
# *
# *  Returns the successor to <i>str</i>. The successor is calculated by
# *  incrementing characters starting from the rightmost alphanumeric (or
# *  the rightmost character if there are no alphanumerics) in the
# *  string. Incrementing a digit always results in another digit, and
# *  incrementing a letter results in another letter of the same case.
# *  Incrementing nonalphanumerics uses the underlying character set's
# *  collating sequence.
# *
# *  If the increment generates a ``carry,'' the character to the left of
# *  it is incremented. This process repeats until there is no carry,
# *  adding an additional character if necessary.
# *
# *     "abcd".succ        #=> "abce"
# *     "THX1138".succ     #=> "THX1139"
# *     "<<koala>>".succ   #=> "<<koalb>>"
# *     "1999zzz".succ     #=> "2000aaa"
# *     "ZZZ9999".succ     #=> "AAAA0000"
# *     "***".succ         #=> "**+"
# */

def is_lower(c):
    return "a" <= c <= "z"

def is_upper(c):
    return "A" <= c <= "Z"

def is_alpha(c):
    return is_lower(c) or is_upper(c)

def is_digit(c):
    return "0" <= c <= "9"

def is_alnum(c):
    return is_alpha(c) or is_digit(c)

def real_succ_char(c, first, last):
    "Returns char, carry"
    if c == last:
        return first, first
    else:
        return chr(ord(c) + 1), None

def succ_char(c):
    if is_lower(c):
        return real_succ_char(c, "a", "z")
    if is_upper(c):
        return real_succ_char(c, "A", "Z")
    # if is_digit(c):
    #     return real_succ_char(c, "0", "9", )
    raise Rb2PyNotImplementedError("succ_char")

def succ(str):
    strlen = len(str)
    if strlen == 0:
        return ""
    if any(not(is_alpha(c)) for c in str):
        raise Rb2PyNotImplementedError("String.succ supported only for plain-ASCII strings")
    new_str = ""
    i = strlen - 1
    while i >= 0:
        char = str[i]
        new_char, carry = succ_char(char)
        new_str = new_char + new_str
        if carry is None:
            return str[:i] + new_str
        i -= 1
    return carry + new_str

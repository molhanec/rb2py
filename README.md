
# Experimental Ruby to Python 3 translator

Contact me

* E-mail: michal AT molhanec DOT net
* Web: http://molhanec.net/
* This project: https://github.com/molhanec/rb2py/

## Licence

Python code in rb2py folder is partly based on Python 3 standard library code.
Notably:
  struct.py

Some comments are copied from the Ruby documentation, mostly method signatures.

All other code is written by Michal Molhanec and it's available under the zlib licence:

  Copyright (C) 2016 Michal Molhanec

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

## Requirements

Generally, the translator requires Ruby 2.2 or higher, or corresponding JRuby
and the translated code should work with Python 3.5 or higher.

For Ruby, whitequark's Parser is required https://github.com/whitequark/parser/ 

Note that the latest version does not parse Prawn library, because Prawn has some 
strings which are not valid in UTF-8. So I recommend version 2.3.0.1:

    gem install parser -v 2.3.0.1

If the translated code uses Time class, tzlocal package is required for Python 3:
    
    pip install tzlocal

## Example 

There is currently single example and that is Prawn PDF library https://github.com/prawnpdf/prawn

The Prawn library is placed in prawn-ruby folder.
It needed few patches which are described in prawn-ruby/patches.txt.
The library in that folder is already patched!

You can run the translation using example_prawn.rb script:

    ruby example_prawn.rb

Results will be put in the prawn-python folder.
**prawn-python folder is always completely deleted before translation!**

If everything went OK, you can try to use the translated library
by running:

    python hello.py
    
which should generate hello.pdf file. 

## Used coding style for Ruby
* single line between methods inside class
* two lines between classes/functions on the module level
* group "end"s, ie. don't put newline between "end"s, ever :)
* {} even for multiline blocks
* (method arguments) instead of method(arguments) if parens are necessary
* I slightly prefer for-in to each. Probably Pythonism :)
* distinguish functions a procedures: method should either return a value or change external state of an object, not both (it can change purely internal things like caches and buffers) 
* oneliners without return, every other method returning useful value with explicit return
 
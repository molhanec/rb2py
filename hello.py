import Prawn
Prawn.image_handler().register(Prawn.JPG)

from rb2py import s

pdf = Prawn.Document()
pdf.text(s("Hello!"))
pdf.image(s("hello.jpg"))
pdf.render_file("hello.pdf")

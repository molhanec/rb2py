#   { a => b, c => d }
# ==>
#   rb2py.OrderedDict(((a: b), (c: d)))
class HashNode
  def real_gen
    $pygen.call('OrderedDict', 'rb2py') {
      # Make tuple around whole values
      $pygen.paren {
        gen_children
      }
    }
  end
end

class MatchNode
  def real_gen
    $pygen.call 'match', 'rb2py' do
      gen_children { $pygen.write ', ' }
      def_node = find_surrounding DefNode
      if def_node.regexp_captures
        $pygen.write ", rb2py_regexp_captures"
      end
    end
  end
end
require_relative "prawn/version"

require_relative "prawn/errors"

require_relative "prawn/utilities"
require_relative "prawn/text"
require_relative "prawn/graphics"
require_relative "prawn/images"
require_relative "prawn/images/image"
require_relative "prawn/images/jpg"
require_relative "prawn/images/png"
require_relative "prawn/stamp"
require_relative "prawn/soft_mask"
require_relative "prawn/security"
require_relative "prawn/transformation_stack"
require_relative "prawn/document"
require_relative "prawn/font"
require_relative "prawn/measurements"
require_relative "prawn/repeater"
require_relative "prawn/outline"
require_relative "prawn/grid"
require_relative "prawn/view"
require_relative "prawn/image_handler"


module Prawn
  BASEDIR = "C:/Ruby22-x64/lib/ruby/gems/2.2.0/gems/prawn-2.0.3"
  DATADIR = "C:/Ruby22-x64/lib/ruby/gems/2.2.0/gems/prawn-2.0.3/data"

  FLOAT_PRECISION = 1.0e-9

  def verify_options(accepted, actual) # @private
    diff = actual.keys - accepted
    unless diff.empty?
      fail Prawn::Errors::UnknownOption,
           "\nDetected unknown option(s): #{diff}\n" \
           "Accepted options are: #{accepted.inspect}"
    end
  end
end

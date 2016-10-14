# Currently setup for the Prawn PDF generating library

# These modules will be converted to classes
$HINTS_MODULE = %w[
  Annotations
  CapStyle
  Color
  Dash
  Destinations
  Formatted
  Graphics
  Images
  Internals
  JoinStyle
  Measurements
  Patterns
  Reader
  SoftMask
  Stamp
  Subset
  Text
  Transformation
  TransformationStack
  Transparency
  View
  Wrap
]


$HINTS_IMPORTS = {
  'forwardable' => :remove,
  'pdf/core/byte_string' => :remove,
  'pdf/core/text' => :remove,
  'ttfunk' => 'TTFunk',
  'ttfunk/subset_collection' => :remove,
}


$HINTS_IMPORTS_ADD = %w(
  PDF
)


# Each step flattens only one level. If you want to flatten more levels,
# see below how it's done for the FormatX0 class.
$HINTS_FLATTEN_CLASSES = %w[
  Prawn::Document::BoundingBox
  Prawn::Document::ColumnBox
  Prawn::Document::MultiBox
  Prawn::Font::DFont
  Prawn::Text::Formatted::Wrap

  Prawn::Images::JPG
  Prawn::Images::PNG

  TTFunk::Subset::Base
  TTFunk::Table::Post::Format10
  TTFunk::Table::Post::Format20
  TTFunk::Table::Post::Format30
  TTFunk::Table::Post::Format40
  TTFunk::Table::Format10
  TTFunk::Table::Format20
  TTFunk::Table::Format30
  TTFunk::Table::Format40
]


# frozen_string_literal: true

# make sure we don't try to create a "CanvasConnect::Version" thing,
# because that doesn't exist
Rails.autoloaders.main.ignore("#{__dir__}/../../lib/canvas_connect/version.rb")

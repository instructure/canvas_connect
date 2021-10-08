# frozen_string_literal: true

# this CANVAS_ZEITWERK constant flag is defined in canvas' "application.rb"
# from an env var. It should be temporary,
# and removed once we've fully upgraded to zeitwerk autoloading.
if defined?(CANVAS_ZEITWERK) && CANVAS_ZEITWERK

  # make sure we don't try to create a "CanvasConnect::Version" thing,
  # because that doesn't exist
  Rails.autoloaders.main.ignore("#{__dir__}/../../lib/canvas_connect/version.rb")

end

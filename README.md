# CanvasConnect

CanvasConnect is an Adobe Connect plugin for [Instructure
Canvas](http://instructure.com). It allows users to create and join Adobe
Connect conferences directly from their courses.

## Installation

Add this line to your application's Gemfile:

    gem 'canvas_connect'

## Usage

CanvasConnect registers itself as a Canvas plugin and can be configured by
going to /plugins in your Canvas instance and entering your Connect information.

CanvasConnect assumes that it's being used inside of a Canvas instance, and
will explode in strange and beautiful ways if you try to run anything in it
outside of Canvas.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

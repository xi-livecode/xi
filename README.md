# Xi

Ξ (Xi /ˈzaɪ/) is a musical pattern language inspired in Tidal and SuperCollider
for building higher-level musical constructs easily.  It's implemented on the
Ruby programming language.

Xi is only a patterns library, but can talk to different backends:

- [SuperCollider](https://github.com/supercollider/supercollider)
- MIDI devices

## Installation

You will need Ruby 2.1+ installed on your system.  Check by running `ruby
-v`.  You will also need Bundler.  Install with `gem install bundler`.

Becase Xi is still in **alpha** stage, you will have to checkout this
repository using Git:

    $ git clone https://github.com/munshkr/xi

After that, change into the new directory and install gem dependencies with
Bundler:

    $ cd xi
    $ bundle install

You're done! Fire up the REPL from `bin/xi`.

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run
`rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/munshkr/xi. This project is intended to be a safe, welcoming
space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The MIT License (MIT)

Copyright (c) 2017 Damián Emiliano Silvani

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

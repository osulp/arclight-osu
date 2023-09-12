# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
pin 'jquery', to: 'https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js'
pin '@github/auto-complete-element', to: 'https://cdn.skypack.dev/@github/auto-complete-element'
pin 'bootstrap', to: 'bootstrap.min.js', preload: true
pin '@popperjs/core', to: 'popper.js', preload: true
pin 'blacklight', preload: true
pin "arclight", to: "arclight/arclight.js"
# TODO: We may be able to move these to a single importmap for arclight.
pin "arclight/oembed_controller", to: "arclight/oembed_controller.js"
pin "arclight/truncate_controller", to: "arclight/truncate_controller.js"

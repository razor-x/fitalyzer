#= require modernizr/modernizr
#= require fastclick
#= require bower-parseuri

'use strict'

parseUri.options.strictMode = true
uri_keys = parseUri(document.URL).queryKey

port = uri_keys.port

protocol = uri_keys.protocol
protocol ?= 'http'

host = uri_keys.host
host ?= 'localhost'

if port then window.local_data_root = "#{protocol}://#{host}:#{port}/data/"

firebase = uri_keys.firebase
if firebase then window.firebase_path = "https://#{firebase}.firebaseio.com/"
window.firebase_path ?= 'https://fitalyzer.firebaseio.com/'

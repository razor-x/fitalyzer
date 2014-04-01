#= require foundation/js/foundation/foundation
#= require foundation/js/foundation/foundation.tooltip
#= require foundation/js/foundation/foundation.reveal
#= require zeroclipboard
#= require fitalyzer

'use strict'

# Invoke Foundation.
$(document).foundation()

# ZeroClipboard.
client = new ZeroClipboard $('.zeroclipboard')

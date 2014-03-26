#= require d3
#= require nvd3
#= require angular
#= require angularfire
#= require firebase-simple-login
#= require angularjs-nvd3-directives
#= require angular-loading-bar

'use strict'

app = angular.module 'analysisApp',
  ['firebase', 'nvd3ChartDirectives', 'chieffancypants.loadingBar']

app.filter 'math', ->
  (input) -> (if input then "#{input}" else '')

app.constant 'solarized',
  base03:  '#002b36'
  base02:  '#073642'
  base01:  '#586e75'
  base00:  '#657b83'
  base0:   '#839496'
  base1:   '#93a1a1'
  base2:   '#eee8d5'
  base3:   '#fdf6e3'
  yellow:  '#b58900'
  orange:  '#cb4b16'
  red:     '#dc322f'
  magenta: '#d33682'
  violet:  '#6c71c4'
  blue:    '#268bd2'
  cyan:    '#2aa198'
  green:   '#859900'

PlotCtrl = ($scope, $http, $log, $firebase, solarized) ->
  $scope.debug = false

  $scope.plotSettings =
    tickFormat: d3.format ',.3f'

  $scope.logged_in = false
  $scope.saving_set_btn = 'save local fits'
  $scope.loading_data = false
  $scope.has_local = false
  $scope.data = []
  $scope.msg_log = []

  $scope.log = (msg, type='log') ->
    $scope.msg_log.push type: type, msg: msg
    if $scope.debug then $log[type](msg)
  log = $scope.log

  local_data_root = window.local_data_root
  local_fits_path = window.local_fits_path
  ref = new Firebase window.firebase_path

  $scope.auth = new FirebaseSimpleLogin ref, (error, user) ->
    if user
      log 'logged in', 'debug'
      $scope.logged_in = true
    else
      log 'logged out', 'debug'
      $scope.logged_in = false

  $scope.sets = $firebase(ref).$child('sets')
  $scope.sets.$on 'loaded', ->
    log '$scope.sets loaded from firebase', 'debug'
    $scope.sets.local = {'name': 'local'}

    if local_data_root
      $scope.set = $scope.sets.local
      $scope.reloadLocalFits()
    else
      loadInitialSet()

  $scope.$watch 'set', ->
    if not $scope.set then return
    log "$scope.set now has name #{$scope.set.name}", 'debug'

    if $scope.set is $scope.sets.local
      $scope.reloadLocalFits()

    $scope.fits = $firebase(ref).$child('fits').$child($scope.set.$id)

    $scope.fits.$on 'loaded', ->
      log "$scope.fits loaded from firebase for #{$scope.set.name}", 'debug'
      initial_fit_id = if window.fit_id then window.fit_id else $scope.fits.$getIndex()[0]
      window.fit_id = null
      $scope.fits.$child(initial_fit_id).$on 'loaded', ->
        $scope.fit = $scope.fits[initial_fit_id]

  $scope.$watch 'fit', ->
    if not $scope.fit then return
    log "$scope.fit now has name #{$scope.fit.name}", 'debug'

    if $scope.set is $scope.sets.local
      loadLocalData "#{local_data_root}#{$scope.fit.name}.json"
    else
      $scope.loading_data = true
      $scope.fits_keys = $scope.fits.$getIndex()
      $scope.data = $firebase(ref).$child('data')
      .$child($scope.set.$id).$child($scope.fit.name)

      $scope.data.$on 'loaded', ->
        log "successfully loaded data with #{$scope.fit.name}", 'debug'
        $scope.loading_data = false
        $scope.chart_data = formatData $scope.data['data'], $scope.data['fit']

  $scope.setFit = (fit) -> $scope.fit = fit

  $scope.addSet = (set) ->
    $scope.saving_set = true
    $scope.saving_set_btn = 'saving now'
    if $scope.set = $scope.sets.local
      log "saving local data set as #{set.name}", 'debug'
      $scope.adding_set = true
      set.time = new Date().getTime()
      $scope.sets.$add set

  ref.child('sets').on 'child_added', (value) ->
    adding_set = $scope.adding_set
    $scope.adding_set = false

    if adding_set
      set_id = value.name()
      set_name = value.val().name
      log "saving local fits for #{set_name}", 'debug'

      angular.forEach $scope.fits, (value, key) ->
        $scope.fits[key].id = key

      ref.child('fits').child(set_id).set(angular.copy $scope.fits)

      i = 0
      angular.forEach $scope.fits, (value, key) ->
        $http method: 'GET', url: "#{local_data_root}#{value.name}.json"
        .success (data, status, headers, config) ->
          log "saving local data for fit named #{value.name} to #{set_name}", 'debug'
          ref.child('data').child(set_id).child(value.name).set(data)
          i++
          if i is $scope.fits.length
            $scope.saving_set_btn = 'saved'
            $scope.saving_set_btn_class = 'success'

  $scope.reloadLocalFits = -> loadLocalFits "#{local_data_root}#{local_fits_path}"

  $scope.fitClass = (fit) -> if fit is $scope.fit then 'active' else ''

  $scope.reloadLocalFitsClass = -> if $scope.set is $scope.sets.local then 'success' else ''

  $scope.incrementFit = (n, check=false) ->
    if $scope.fits
      if $scope.set is $scope.sets.local
        index = $scope.fits.indexOf($scope.fit)
      else if $scope.fits_keys
        index = $scope.fit.id

      if check then return $scope.fits[index + n]?
      $scope.fit = $scope.fits[index + n]

  $scope.deleteSet = (set) ->
    set_id = $scope.set.$id
    ref.child('data').child(set_id).remove()
    ref.child('fits').child(set_id).remove()
    $scope.sets.$remove(set_id)

  formatData = (data, fit) ->
    [
      {
        key: 'Fit'
        values: fit
        color: solarized.base03
      },
      {
        key: 'Data'
        values: data
        color: solarized.cyan
      }
    ]

  loadLocalFits = (path) ->
    $http method: 'GET', url: path
    .success (data, status, headers, config) ->
      log "successfully loaded local fits with status: #{status} ", 'debug'

      unless (if $scope.set then $scope.set.name) is 'local'
        $scope.set = $scope.sets.local

      $scope.fits = data
      $scope.fit = data[0]

    .error (data, status, headers, config) ->
      log "local fits not found with status: #{status} ", 'debug'
      loadInitialSet()

  loadLocalData = (path) ->
    $http method: 'GET', url: path
    .success (data, status, headers, config) ->
      log "successfully loaded local data with status: #{status} ", 'debug'
      $scope.saving_set_btn = 'save local fits'
      $scope.saving_set_btn_class = ''
      $scope.saving_set = false
      $scope.has_local = true
      $scope.chart_data = formatData data.data, data.fit

    .error (data, status, headers, config) ->
      log "local data not found with status: #{status} ", 'debug'

  loadInitialSet = ->
    initial_set_id = if window.set_id then window.set_id else $scope.sets.$getIndex()[0]
    window.set_id = null
    $scope.sets.$child(initial_set_id).$on 'loaded', ->
      $scope.set = $scope.sets[initial_set_id]

app.controller 'PlotCtrl', ['$scope', '$http', '$log', '$firebase', 'solarized', PlotCtrl]

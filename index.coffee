http  = require 'http'
url   = require 'url'
querystring = require 'querystring'

class ES
  constructor: (@defaults = {}) ->
    @defaults.host = params.host || 'localhost'
    @defaults.port = params.port || 9200

  setIndex: (index, type = null) ->
    @defaults.index = index
    @defaults.type  = type
    @

  setType: (type) ->
    @defaults.type  = type
    @

  generatePath: (params) ->
    res = ''
    index = params.index || @defaults.index
    type  = params.type || @defaults.index
    if @_index
      res += '/' + @_index
      res += '/' + @_type if @_type
    res += '/' + path if path
    res += '?' + querystring.stringify query if query
    res

  fixArgs: (path, data, query, callback) ->
    if 'function' == typeof path
      callback  = path
      path      = data = query = null
    else if path && 'object' == typeof path
      callback  = query
      query     = data
      data      = path
      path      = null
    if 'function' == typeof data
      callback  = data
      data      = query = null
    else if 'function' == typeof query
      callback  = query
      query     = null
    [path, data, query, callback]

  request: (params, callback) ->
    req = http.request
      host:     params.host || @
      port:     @_port
      method:   method
      path:     @generatePath path, query
      headers:  'Content-Type': 'application/json'
      (res) ->
        res_data = ''
        res.on 'data', (chunk) ->
          res_data += chunk
        res.on 'error', (err) ->
          callback && callback err
        res.on 'end', ->
          unless 300 > @statusCode
            return callback && callback new Error res_data
          try
            obj = JSON.parse res_data
          catch err
            return callback && callback err
          callback && callback null, obj
    .on 'error', (err) ->
      callback && callback err
    if data
      req.write JSON.stringify data
    req.end()

  _request_without_body: (method, path, query, callback) ->
    if 'function' == typeof path
      callback = path
      path = query = null
    else if 'object' == typeof path
      callback = query
      query = path
      path = null
    else if 'function' == typeof query
      callback = query
      query = null
    @request method, path, null, query, callback

  # restful methods
  post: (path, data, query, callback) ->
    @request 'POST', path, data, query, callback

  get: (path, query, callback) ->
    @_request_without_body 'GET', path, query, callback

  put: (path, data, query, callback) ->
    @request 'PUT', path, data, query, callback

  delete: (path, query, callback) ->
    @_request_without_body 'DELETE', path, query, callback

  # shortcuts
  putMapping: (data, query, callback) ->
    @put '_mapping', data, query, callback

  deleteMapping: (query, callback) ->
    @delete '_mapping', query, callback

  search: (data, query, callback) ->
    @post '_search', data, query, callback

  index: (id, data, query, callback) ->
    if id && 'object' != typeof id
      @put id, data, query, callback
    else
      @post id, data, query, callback

module.exports = ES


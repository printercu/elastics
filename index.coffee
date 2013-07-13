http  = require 'http'
url   = require 'url'
qs    = require 'querystring'
util  = require 'util'

module.exports = class Elastics
  @normalizeFilters: (filters) ->
    return filters unless util.isArray filters
    if 1 < filters.length
      and: filters: filters
    else
      filters[0]

  @normalizeQuery: (query, filters) ->
    filter = @normalizeFilters filters

    query ||= match_all: {}
    if filter
      filtered:
        query:  query
        filter: filter
     else
      query

  @termsQuery: (field, val) ->
    query = if util.isArray val then 'terms' else 'term'
    result = {}
    result[query] = {}
    result[query][field] = val
    result

  constructor: (@defaults = {}) ->
    @defaults.host ||= 'localhost'
    @defaults.port ||= 9200

  setIndex: (index, type) ->
    @defaults.index = index || null
    @defaults.type  = type  || null
    @

  setType: (type) ->
    @defaults.type  = type
    @

  generatePath: (params) ->
    str = ''
    index = params.index  || @defaults.index
    type  = params.type   || @defaults.type
    if index?
      str += '/' + index
      str += '/' + type if type?
    path = if params.id? then params.id else params.path
    str += '/' + path if path?
    str += '?' + qs.stringify params.query if params.query
    str

  request: (params, callback) ->
    req = http.request
      host:     params.host   || @defaults.host
      port:     params.port   || @defaults.port
      method:   params.method || 'GET'
      path:     @generatePath params
      headers:  'Content-Type': 'application/json'
      (res) ->
        res_data = ''
        res.on 'data', (chunk) ->
          res_data += chunk
        res.on 'error', (err) ->
          callback? err
        res.on 'end', ->
          unless 300 > @statusCode
            return callback? new Error res_data
          try
            obj = JSON.parse res_data
          catch err
            return callback? err
          callback? null, obj
    .on 'error', (err) ->
      callback? err
    if params.data
      req.write JSON.stringify params.data
    req.end()

  # shortcuts
  putMapping: (params, callback) ->
    params.path = '_mapping'
    @put params, callback

  search: (params, callback) ->
    params.path = '_search'
    @post params, callback

  index: (params, callback) ->
    if params.id
      @put params, callback
    else
      @post params, callback

  for method in ['GET', 'PUT', 'POST', 'DELETE']
    do (method) =>
      @prototype[method.toLowerCase()] = (params, callback) ->
        params.method = method
        @request params, callback

  set: (id, data, callback) ->
    @put
      id:   id
      data: data
      callback

  get: (params, callback) ->
    params = id: params unless typeof params == 'object'
    params.method = 'GET'
    @request params, callback

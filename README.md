# elastics
Simple & handy client for elasticsearch. It's just a wrapper around
`http.request` with shortcuts for elasticsearch.

It implements all available functionality & even upcoming.

Be careful while using settings for default type & index: they are client's
instance variables. So if you are going to have one client in an application
you'd better set them explicitly in each call. JS is so _asynchronous..._

## usage

```coffee
Elastics = require 'elastics'
es = new Elastics
  host:  hostname # default 'localhost'
  port:  port     # default 9200
  index: index    # default null
  type:  type     # default null
```

This params are stored in `es.defaults`. You can change them with:

- `setIndex(index, [type = null])`
- `setType(type)`

For the first time I've made all the methods adaptive to arguments. But then
there have appeared to much significant arguments so I gave it up.

So all the methods take two args: object with parameters & callback.
For now you can omit callback but not params.

### params fields:
- `method` - http request method
- `index`
- `type`
- `path` - last part for url
- `id` - same as `path` but with higher priority
- `query` - query string for url. you can set routing params here
- `data` - request body

You can omit fields stored in `defaults`

### lowest level
`request(params, [callback])`

### request-type level
`get()`, `put()`, `post()`, `delete()` - just set the method

### highest level
- `putMapping()` - put with `path = '_mapping'`
- `search()` - post with `path = '_search'`
- `index()` - if `id` field is set then `put` else `post`

## few examples
```coffee
es.setType()
# index:null, type: null

es.get {}
# GET http://host::port/

es.post index: 'index'
# POST http://host::port/index

es.setIndex 'other_index', 'type'
mapping = type:
  fields:
    field_one: type: 'string'
es.putMapping data: mapping
# PUT http://host::port/other_index/type/_mapping
# body is json of mapping

es.get index: 'one', type: 'two', id: 'three'
# GET http://host::port/one/two/three
```

see tests

## LICENSE
BSD

assert  = require 'assert'
flow    = require 'flow'
Es      = require '../'

TEST_INDEX  = 'test_index'
TEST_TYPE   = 'test_type'
MAPPING = {}
MAPPING[TEST_TYPE] = fields: test: type: 'string'

describe 'Elastics', ->
  client = null

  beforeEach ->
    client = new Es(index: TEST_INDEX)

  it 'should create client', () ->
    assert.equal 'object', typeof client

  it 'should accept index & type', ->
    client.setIndex()
    assert.deepEqual [null, null], [client.defaults.index, client.defaults.type]
    client.setIndex('index', 'type')
    assert.deepEqual ['index', 'type'], [client.defaults.index, client.defaults.type]
    client.setIndex('index2')
    assert.deepEqual ['index2', null], [client.defaults.index, client.defaults.type]
    client.setType('type2')
    assert.deepEqual ['index2', 'type2'], [client.defaults.index, client.defaults.type]

  describe 'indices & types', ->
    it 'should create index', (done) ->
      flow.exec(
        -> client.delete {}, @
        -> client.post {}, @
        (err, data) ->
          throw err if err
          done()
      )

    it 'should read index', (done) ->
      flow.exec(
        -> client.delete {}, @
        -> client.post {}, @
        -> client.get path: '_mapping',
          @
        (err, data) ->
          throw err if err
          done()
      )

  it 'should put mapping', (done) ->
    flow.exec(
      -> client.post {}, @
      -> client.setType(TEST_TYPE).putMapping data: MAPPING,
        @
      (err, data) ->
        throw err if err
        done()
    )

  describe 'should work with items:', ->
    item1 = val: 'item1', tag: 'tag'
    item2 = val: 'item2', tag: 'tag'

    beforeEach (done) ->
      client.setType TEST_TYPE
      flow.exec(
        #-> client.setIndex(TEST_INDEX).delete @
        #-> client.post @
        -> client.delete {}, @
        -> client.putMapping data: MAPPING,
          @
        -> done()
      )

    it 'index', (done) ->
      flow.exec(
        -> client.index data: item1,
          @
        (err, data) ->
          throw err if err
          client.get id: data._id,
            @
        (err, data) ->
          throw err if err
          assert.deepEqual data._source, item1
          done()
      )

    it 'update', (done) ->
      flow.exec(
        -> client.index id: 1, data: item1,
          @
        -> client.index id: 1, data: item2,
          @
        (err, data) ->
          throw err if err
          client.get id: 1,
            @
        (err, data) ->
          throw err if err
          assert.deepEqual data._source, item2
          done()
      )

    it 'delete', (done) ->
      flow.exec(
        -> client.index id: 2, data: item1,
          @
        -> client.delete id: 2,
          @
        (err, data) ->
          throw err if err
          client.get id: 2,
            @
        (err, data) ->
          assert.notEqual null, err
          done()
      )

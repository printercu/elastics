assert  = require 'assert'
flow    = require 'flow-coffee'
Es      = require '../'

TEST_INDEX  = 'test_index'
TEST_TYPE   = 'test_type'
MAPPING = {}
MAPPING[TEST_TYPE] = fields: test: type: 'string'

describe 'Elastics', ->
  client = null

  beforeEach ->
    client = new Es index: TEST_INDEX

  it 'creates client', ->
    assert.equal 'object', typeof client

  it 'accepts index & type', ->
    client.setIndex()
    assert.deepEqual [null, null], [client.defaults.index, client.defaults.type]
    client.setIndex('index', 'type')
    assert.deepEqual ['index', 'type'], [client.defaults.index, client.defaults.type]
    client.setIndex('index2')
    assert.deepEqual ['index2', null], [client.defaults.index, client.defaults.type]
    client.setType('type2')
    assert.deepEqual ['index2', 'type2'], [client.defaults.index, client.defaults.type]

  it 'creates index', (done) ->
    flow.exec(
      -> client.delete {}, @
      -> client.post {}, @
      done
    )

  it 'reads index', (done) ->
    flow.exec(
      -> client.delete {}, @
      -> client.post {}, @
      -> client.get { path: '_mapping' }, @
      done
    )

  it 'puts mapping', (done) ->
    flow.exec(
      -> client.post {}, @
      -> client.setType(TEST_TYPE).putMapping { data: MAPPING }, @
      done
    )

  describe 'works with items:', ->
    item1 = val: 'item1', tag: 'tag'
    item2 = val: 'item2', tag: 'tag'

    beforeEach (done) ->
      client.setType TEST_TYPE
      flow.exec(
        #-> client.setIndex(TEST_INDEX).delete @
        #-> client.post @
        -> client.delete      {}, @
        -> client.putMapping  { data: MAPPING }, @
        done
      )

    it 'index', (done) ->
      flow.exec(
        -> client.index { data: item1 }, @
        (err, data) -> client.get { id: data._id }, @
        (err, data) -> done null, assert.deepEqual data._source, item1
      ).error done

    it 'update', (done) ->
      flow.exec(
        -> client.index { id: 1, data: item1 }, @
        -> client.index { id: 1, data: item2 }, @
        -> client.get   { id: 1 }, @
        (err, data) -> done null, assert.deepEqual data._source, item2
      ).error done

    it 'delete', (done) ->
      flow.exec(
        -> client.index { id: 2, data: item1 }, @
        -> client.delete { id: 2 }, @
        (err, data) ->
          assert.equal err, null
          client.get { id: 2 }, @
        (err, data) ->
          assert.notEqual err, null
          done()
      )

    it 'set & get by id', (done) ->
      flow.exec(
        -> client.set 3, item1, @
        -> client.get 3, @
        (err, data) -> done null, assert.deepEqual data._source, item1
      ).error done

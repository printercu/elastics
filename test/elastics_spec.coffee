assert  = require 'assert'
flow    = require 'flow'
Es      = require '../'

TEST_INDEX  = 'test_index'
TEST_TYPE   = 'test_type'
MAPPING = {}
MAPPING[TEST_TYPE] = fields: test: type: 'string'

describe 'Es', ->
  client = null

  beforeEach ->
    client = new Es()

  it 'should fix args', () ->
    f = -> 53
    str = 'str'
    o1 = {a:1}
    o2 = {b:2}
    assert.deepEqual [null, null, null, f], client.fixArgs(f), '1'
    assert.deepEqual [str,  null, null, f], client.fixArgs(str, f), '2'
    assert.deepEqual [str,  o1,   null, f], client.fixArgs(str, o1, f), '3'
    assert.deepEqual [str,  o1,   o2,   f], client.fixArgs(str, o1, o2, f), '4'
    assert.deepEqual [null, o1,   o2,   f], client.fixArgs(o1, o2, f), '5'
    assert.deepEqual [null, o1,   null, f], client.fixArgs(o1, f), '6'
    str = null
    o1 = null
    o2 = null
    assert.deepEqual [null, null, null, f], client.fixArgs(f), '7'
    assert.deepEqual [str,  null, null, f], client.fixArgs(str, f), '8'
    assert.deepEqual [str,  o1,   null, f], client.fixArgs(str, o1, f), '9'
    assert.deepEqual [str,  o1,   o2,   f], client.fixArgs(str, o1, o2, f), '10'
    assert.deepEqual [null, o1,   o2,   f], client.fixArgs(o1, o2, f), '11'
    assert.deepEqual [null, o1,   null, f], client.fixArgs(o1, f), '12'

  it 'should create client', () ->
    assert.equal 'object', typeof client

  it 'should accept index & type', ->
    assert.deepEqual [null, null], [client._index, client._type]
    client.setIndex('index', 'type')
    assert.deepEqual ['index', 'type'], [client._index, client._type]
    client.setIndex('index2')
    assert.deepEqual ['index2', null], [client._index, client._type]
    client.setType('type2')
    assert.deepEqual ['index2', 'type2'], [client._index, client._type]

  describe 'indices & types', ->
    it 'should create index', (done) ->
      flow.exec(
        -> client.setIndex(TEST_INDEX).delete @
        -> client.post @
        (err, data) ->
          throw err if err
          done()
      )

    it 'should read index', (done) ->
      flow.exec(
        #-> client.setIndex(TEST_INDEX).delete @
        #-> client.post @
        -> client.get '_mapping', @
        (err, data) ->
          throw err if err
          done()
      )

  describe 'mappings', ->
    it 'should create & delete', (done) ->
      client.setIndex(TEST_INDEX, TEST_TYPE)
      flow.exec(
        -> client.putMapping MAPPING, @
        (err, data) ->
          throw err if err
          client.deleteMapping @
        (err, data) ->
          throw err if err
          done()
      )

  describe 'items', ->
    item1 = val: 'item1', tag: 'tag'
    item2 = val: 'item2', tag: 'tag'

    beforeEach (done) ->
      flow.exec(
        #-> client.setIndex(TEST_INDEX).delete @
        #-> client.post @
        -> client.setIndex(TEST_INDEX, TEST_TYPE).delete @
        -> client.setType(TEST_TYPE).putMapping MAPPING, @
        -> done()
      )

    it 'should index item', (done) ->
      flow.exec(
        ->
          client.index item1, @
        (err, data) ->
          throw err if err
          client.get data._id, @
        (err, data) ->
          throw err if err
          done()
      )

    it 'should update', (done) ->
      flow.exec(
        -> client.index 1, item1, @
        -> client.get 1, @
        (err, data) ->
          throw err if err
          assert.deepEqual data._source, item1
          item1.val = 'item'
          client.index 1, item1, @
        (err, data) ->
          throw err if err
          client.get 1, @
        (err, data) ->
          throw err if err
          assert.deepEqual data._source, item1
          done()
      )

    it 'should delete', (done) ->
      flow.exec(
        -> client.index 2, item1, @
        -> client.get 2, @
        -> client.delete 2, @
        (err, data) ->
          throw err if err
          done()
      )

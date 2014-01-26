_ = require('underscore')
assert = require('assert')
testHelper = require('./test_helper')
deep = require('../lib/deep')

describe 'deep module', () ->

  describe 'isPlainObject()', () ->

    it 'object literals are plain objects', (done) ->
      assert deep.isPlainObject({})
      done()

    it 'objects created with `new Object` are plain objects', (done) ->
      assert deep.isPlainObject(new Object)
      done()

    it 'global is a plain object', (done) ->
      assert deep.isPlainObject(global)
      done()

    it 'arrays are not plain objects', (done) ->
      assert !deep.isPlainObject([])
      done()

    it 'functions are not plain objects', (done) ->
      assert !deep.isPlainObject(() ->)
      done()

    it 'Buffers are not plain objects', (done) ->
      assert !deep.isPlainObject(new Buffer(1))
      done()

    it 'Custom objects are not plain objects', (done) ->
      Foobar = () ->
      assert !deep.isPlainObject(new Foobar)
      done()

  describe 'clone()', () ->

    beforeEach (done) ->
      class Foobar
      @original =
          arr: [
            (arg) -> "Hello #{arg}!"
            'hello!'
            1
            new Buffer(1)
            {
              foo: 'bar'
              foobar: new Foobar
            }
          ]
          obj:
            a: [
              {
                b: {
                  c: []
                }
              }
            ]
            z: 'just a string!'
      @clone = deep.clone(@original)
      done()

    it 'should generate new plain objects and arrays', (done) ->
      @clone.obj.a[0].b.c.push 0
      assert.notEqual @clone.obj.a[0].b.c.length, @original.obj.a[0].b.c.length

      @clone.arr[4].bar = 'foo'
      assert !@original.arr[4].bar?

      done()

    it 'should preserve references to functions', (done) ->
      assert.equal @clone.arr[0], @original.arr[0]
      done()

    it 'should preserve references to Buffers', (done) ->
      assert.equal @clone.arr[3].constructor.name, 'Buffer'
      assert.equal @clone.arr[3], @original.arr[3]
      done()

    it 'should preserve references to custom objects', (done) ->
      assert.equal @clone.arr[4].foobar.constructor.name, 'Foobar'
      assert.equal @clone.arr[4].foobar, @original.arr[4].foobar
      done()

  describe 'equals()', () ->

    it 'should return true for scalar data that are identical', ->
      a = 1
      b = 1
      assert deep.equals(a, b)

      a = "Hello"
      b = "Hello"
      assert deep.equals(a, b)

      a = false
      b = false
      assert deep.equals(a, b)

    it 'should return false for scalar data that are different', ->
      a = 1
      b = 2
      assert !deep.equals(a, b)

      a = "Hello"
      b = "Goodbye"
      assert !deep.equals(a, b)

      a = false
      b = true
      assert !deep.equals(a, b)

    it 'should return true for matching references to non-plain objects', ->
      klass = (@v) ->
      a = b = new klass("Hello")
      assert deep.equals(a, b)

    it 'should return false for non-matching references to similar non-plain objects', ->
      klass = (@v) ->
      a = new klass("Hello")
      b = new klass("Hello")
      assert !deep.equals(a, b)

    it 'should return true for simple plain objects that are identical', ->
      a = x: 1, y: 2
      b = x: 1, y: 2
      assert deep.equals(a, b)

    it 'should return true for simple plain objects that are identical except for order', ->
      a = x: 1; a.y = 2
      b = y: 2; b.x = 1
      assert deep.equals(a, b)

    it 'should return false for simple plain objects that differ', ->
      a = x: 1, y: 2
      b = x: 1, y: 3
      assert !deep.equals(a, b)

    it 'should return true for arrays that are identical', ->
      a = [1, 2, 3, 4]
      b = [1, 2, 3, 4]
      assert deep.equals(a, b)

    it 'should return false for arrays that are identical except for order', ->
      a = [1, 2, 3, 4]
      b = [1, 2, 4, 3]
      assert !deep.equals(a, b)

    it 'should return false for arrays that differ in length', ->
      a = [1, 2, 3, 4]
      b = [1, 2, 3]
      assert !deep.equals(a, b)

    it 'should return false for arrays that differ in content', ->
      a = [1, 2, 3, 4]
      b = [5, 6, 7, 8]
      assert !deep.equals(a, b)

    it 'should return true for deeply nested content that is identical', ->
      klass = (@v) ->
      obj1 = new klass('Hello')
      obj2 = new klass('Goodbye')

      a = [
        1
        [false, null, undefined, obj1]
        {x: 3, y: 4, z: [5, 6, obj2, 'some string']}
      ]

      b = [
        1
        [false, null, undefined, obj1]
        {x: 3, y: 4, z: [5, 6, obj2, 'some string']}
      ]

      assert deep.equals(a, b)

    it 'should return false for deeply nested content that differs slightly', ->
      klass = (@v) ->
      obj1 = new klass('Hello')
      obj2 = new klass('Goodbye')

      a = [
        1
        [false, null, undefined, obj1]
        {x: 3, y: 4, z: [5, 6, obj2, 'some string']}
      ]

      b = [
        1
        [false, null, undefined, obj1]
        {x: 3, y: 4, z: [5, 6, obj2, 'some string that is different']}
      ]

      assert !deep.equals(a, b)

  describe 'extend()', () ->

    it 'should accept multiple sources', (done) ->
      a = a: 1
      b = b: 2
      c = c: 3
      deep.extend a, b, c
      assert.deepEqual a, a: 1, b: 2, c: 3
      done()

    it 'should prioritize latter arguments', (done) ->
      a = a: 1
      b = a: 2
      c = a: 3
      deep.extend a, b, c
      assert.deepEqual a, a: 3
      done()

    it 'should extend recursively', (done) ->
      a =
        alpha:
          beta:
            charlie: 1

      b =
        alpha:
          beta:
            delta: 3
        epsilon: 2

      deep.extend a, b

      assert.deepEqual a,
        alpha:
          beta:
            charlie: 1
            delta: 3
        epsilon: 2

      done()

    it 'should create copies of nested objects', (done) ->
      a =
        alpha:
          beta:
            charlie: 1
      b =
        alpha:
          beta:
            delta: [1, 2, 3, 4]
      deep.extend a, b
      b.alpha.beta.delta.push(5)
      assert.equal a.alpha.beta.delta.length, b.alpha.beta.delta.length - 1
      done()

  describe 'select()', () ->

    before (done) ->
      @container =
          arr: [
            (arg) -> "Hello #{arg}!"
            'hello!'
            1
            (arg) -> "Goodbye #{arg}!"
            {
              foo: 'bar'
              foobar: (arg) -> "Hello again #{arg}!"
            }
          ]
          obj:
            a: [
              {
                b: {
                  c: (arg) -> "Goodbye again #{arg}!"
                }
              }
            ]
            z: 'just a string!'
      @selected = deep.select(@container, _.isFunction)
      done()

    it "should find all objects that satisfy the filter", (done) ->
      assert.equal @selected.length, 4
      assert.deepEqual @selected[0].value, @container.arr[0]
      assert.deepEqual @selected[1].value, @container.arr[3]
      assert.deepEqual @selected[2].value, @container.arr[4].foobar
      assert.deepEqual @selected[3].value, @container.obj.a[0].b.c
      done()

    it "should report paths to objects that satisfy the filter", (done) ->
      assert.deepEqual @selected[0].path, [ 'arr', '0' ]
      assert.deepEqual @selected[1].path, [ 'arr', '3' ]
      assert.deepEqual @selected[2].path, [ 'arr', '4', 'foobar' ]
      assert.deepEqual @selected[3].path, [ 'obj', 'a', '0', 'b', 'c' ]
      done()

  describe "set()", () ->

    beforeEach (done) ->
      @obj =
        arr: []
      done()

    it 'should set values using paths', (done) ->
      deep.set @obj, [ 'arr', '0' ], 'new value'
      assert.equal @obj.arr[0], 'new value'
      done()

    it 'should set values with path lenghts of 1', (done) ->
      deep.set @obj, [ 'new' ], 'new value'
      assert.equal @obj.new, 'new value'
      done()

  describe "transform()", () ->

    beforeEach (done) ->
      @original =
        arr: [
          (arg) -> "Hello #{arg}!"
          'hello!'
          1
          (arg) -> "Goodbye #{arg}!"
          {
            foo: 'bar'
            foobar: (arg) -> "Hello again #{arg}!"
            bar: 3
          }
        ]
        obj:
          a: [
            {
              b: {
                c: (arg) -> "Goodbye again #{arg}!"
              }
            }
            5
          ]
          z: 'just a string!'
      @transformed = deep.transform(@original, _.isNumber, (v) -> v + 1)
      done()

    it 'should apply transform to values that satisfy the filter', (done) ->
      assert.equal @transformed.arr[2], 2
      assert.equal @transformed.arr[4].bar, 4
      assert.equal @transformed.obj.a[1], 6
      done()

    it 'should not affect values that do not satisfy the filter', (done) ->
      assert.equal @transformed.arr[0], @original.arr[0]
      assert.equal @transformed.arr[1], @original.arr[1]
      assert.equal @transformed.obj.z, @original.obj.z
      done()
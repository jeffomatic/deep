_ = require('underscore')
should = require('should')
testHelper = require('./test_helper')
deep = require('../lib/deep')

describe 'deep module', () ->

  describe 'isPlainObject()', () ->

    it 'object literals are plain objects', (done) ->
      deep.isPlainObject({}).should.eql true
      done()

    it 'objects created with `new Object` are plain objects', (done) ->
      deep.isPlainObject(new Object).should.eql true
      done()

    it 'global is a plain object', (done) ->
      deep.isPlainObject(global).should.eql true
      done()

    it 'arrays are not plain objects', (done) ->
      deep.isPlainObject([]).should.eql false
      done()

    it 'functions are not plain objects', (done) ->
      deep.isPlainObject(() ->).should.eql false
      done()

    it 'Buffers are not plain objects', (done) ->
      deep.isPlainObject(new Buffer(1)).should.eql false
      done()

    it 'Custom objects are not plain objects', (done) ->
      Foobar = () ->
      deep.isPlainObject(new Foobar).should.eql false
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
      @clone.obj.a[0].b.c.length.should.not.eql @original.obj.a[0].b.c.length

      @clone.arr[4].bar = 'foo'
      (@original.arr[4].bar?).should.eql false

      done()

    it 'should preserve references to functions', (done) ->
      @clone.arr[0].should.eql @original.arr[0]
      done()

    it 'should preserve references to Buffers', (done) ->
      @clone.arr[3].constructor.name.should.eql 'Buffer'
      @clone.arr[3].should.eql @original.arr[3]
      done()

    it 'should preserve references to custom objects', (done) ->
      @clone.arr[4].foobar.constructor.name.should.eql 'Foobar'
      @clone.arr[4].foobar.should.eql @original.arr[4].foobar
      done()

  describe 'extend()', () ->

    it 'should accept multiple sources', (done) ->
      a = a: 1
      b = b: 2
      c = c: 3
      deep.extend a, b, c
      a.should.eql a: 1, b: 2, c: 3
      done()

    it 'should prioritize latter arguments', (done) ->
      a = a: 1
      b = a: 2
      c = a: 3
      deep.extend a, b, c
      a.should.eql a: 3
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
      a.should.eql(
        alpha:
          beta:
            charlie: 1
            delta: 3
        epsilon: 2
      )
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
      a.alpha.beta.delta.length.should.eql b.alpha.beta.delta.length - 1
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
      @selected.length.should.eql 4
      @selected[0].value.should.eql @container.arr[0]
      @selected[1].value.should.eql @container.arr[3]
      @selected[2].value.should.eql @container.arr[4].foobar
      @selected[3].value.should.eql @container.obj.a[0].b.c
      done()

    it "should report paths to objects that satisfy the filter", (done) ->
      @selected[0].path.should.eql [ 'arr', '0' ]
      @selected[1].path.should.eql [ 'arr', '3' ]
      @selected[2].path.should.eql [ 'arr', '4', 'foobar' ]
      @selected[3].path.should.eql [ 'obj', 'a', '0', 'b', 'c' ]
      done()

  describe "set()", () ->

    beforeEach (done) ->
      @obj =
        arr: []
      done()

    it 'should set values using paths', (done) ->
      deep.set @obj, [ 'arr', '0' ], 'new value'
      @obj.arr[0].should.eql 'new value'
      done()

    it 'should set values with path lenghts of 1', (done) ->
      deep.set @obj, [ 'new' ], 'new value'
      @obj.new.should.eql 'new value'
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
      @transformed.arr[2].should.eql 2
      @transformed.arr[4].bar.should.eql 4
      @transformed.obj.a[1].should.eql 6
      done()

    it 'should not affect values that do not satisfy the filter', (done) ->
      @transformed.arr[0].should.eql @original.arr[0]
      @transformed.arr[1].should.eql @original.arr[1]
      @transformed.obj.z.should.eql @original.obj.z
      done()
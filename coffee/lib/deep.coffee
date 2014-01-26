_ = require('underscore')
{puts} = require('util')
deep =

  # Returns true for object literals and objects created with `new Object`.
  # WARNING: no support for quasi-object browser constructs like window, etc.
  isPlainObject: (obj) ->
    return false unless obj?.constructor?
    obj.constructor.name == 'Object'

  # Performs a standard deep clone, preserving references to functions.
  clone: (obj) ->
    if _.isArray(obj)
      clone = []
      clone.push(deep.clone(v)) for v in obj
      clone
    else if deep.isPlainObject(obj)
      clone = {}
      clone[k] = deep.clone(v) for k, v of obj
      clone
    else
      obj

  equals: (a, b) ->
    if a == b
      true
    else if _.isArray(a)
      return false unless _.isArray(b) && a.length == b.length
      for i in [0...a.length]
        return false unless deep.equals(a[i], b[i])
      true
    else if deep.isPlainObject(a)
      size_a = _.size(a)
      return false unless deep.isPlainObject(b) && size_a == _.size(b)
      for k of a
        return false unless deep.equals(a[k], b[k])
      true
    else
      false

  extend: (destination, sources...) ->
    for source in sources
      for k of source
        if deep.isPlainObject(destination[k]) && deep.isPlainObject(source[k])
          deep.extend destination[k], source[k]
        else
          destination[k] = deep.clone(source[k])

    destination

  # Recusrively traverses objects and accumulates values that satisfy a filter
  # function, along with the path of references required to access the value.
  select: (root, filter, path = []) ->
    # Build a list of serialized function bodies and their paths in the object
    selected = []

    if filter(root)
      selected.push path: path, value: root
    else if _.isObject(root)
      for k, v of root
        elementPath = _.clone(path)
        elementPath.push(k)
        selected = selected.concat(deep.select(v, filter, elementPath))

    selected

  # Populate an object with functions at the specified paths.
  set: (root, path, value) ->
    path = _.clone(path)
    lastPath = path.pop()
    root = root[pathElement] for pathElement in path
    root[lastPath] = value

  # Recursively searches for objects that satisfy a filter value and replace
  # them with transformed values.
  transform: (obj, filter, transform) ->
    if filter(obj)
      transform obj
    else if _.isArray(obj)
      transformed = []
      transformed.push deep.transform(v, filter, transform) for v in obj
      transformed
    else if deep.isPlainObject(obj)
      transformed = {}
      transformed[k] = deep.transform(v, filter, transform) for k, v of obj
      transformed
    else
      obj

module.exports = deep
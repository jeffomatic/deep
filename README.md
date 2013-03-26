# deep

This library contains utilities for manipulating deeply-nested data structures. These functions only perform recursive traversal of arrays and "plain" objects, that is, those objects that were created using object literals (`{}`) or `new Object`.

## Installation

    npm install deep

## Function reference

### isPlainObject(object)

```js
deep.isPlainObject({}); // true
deep.isPlainObject(new Object); // true
deep.isPlainObject([]); // false
deep.isPlainObject(new function(){}); // false
```

This function works by checking to see if the argument's constructor's `name` is `Object`.

----

### clone(object)

```js
x = {
  a: 1,
  b: [ 2, 3, function(arg) { return arg; } ]
};

y = deep.clone(x) // -> deep-copies x, preserving references to nested functions
```

This will preserve references to all non-array, non-plain objects, including functions.

----

### extend(destination, source, ...)

```js
x = { a: { b: { c: 1 } }, d: 2, e: 3 }
y = { a: { b: { c: 4, f: 5 }, d: 6, g: 7 } }
z = { a: { b: { c: 8 } }, h: 9 }

deep.extend(x, y, z)

// x -> { a: { b: { c: 8, f: 5 }, d: 6, e: 3, g: 7 }, h: 9 }
```

Recursively merges each `source` object into `destination`, preserving any nested structure common among the sources. Precedence is given to the rightmost sources.

----

### select(root, filter)

```js
x = {
  a: 1,
  b: [ 2, 3, 'hello' ]
};

deep.select(x, function(obj) { return typeof obj == 'number' } );

// -> [
//      { value: 1, path: [ 'a' ] },
//      { value: 2, path: [ 'b', '0' ] },
//      { value: 3, path: [ 'c', '1' ] }
//    ]
```

Recursively traverses arrays and plain objects for any values that satisfy the test defined by the `filter` function. The path of references to each value is returned.

----

### set(root, path, value)

```js
x = { a: { b: [ { c: 5 } ] } }
deep.set(x, ['a', 'b', 0, 'c'], 'hello');

// x -> { a: { b: [ { c: 'hello' } ] } }
```

Inserts `value` into the `root` object by traversing a sequence of references defined by `path`.

----

### transform(object, filter, transform)

```js
x = {
  a: 1,
  b: [ 2, 3, 'hello' ]
};

deep.transform(
  x,
  function(obj) { return typeof obj == 'string' },
  function(obj) { return obj.length }
);

// -> {
//      a: 1,
//      b: [ 2, 3, 5 ]
//    }
```

Returns a deep copy of `object`, using the `transform` function to modify any elements that satisfy the `filter` function.

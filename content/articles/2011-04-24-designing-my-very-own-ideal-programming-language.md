---
tags: random
---

# Designing my very own ideal programming language
In 2009 I made the switch to Python, after having worked exclusively with PHP and Javascript for almost a decade. I really like the language, much more than I ever liked PHP. Of course it's not perfect (see one of my first posts called [Things I hate about Python and Django](/articles/2009/things-i-hate-about-python-and-django/)), but I never really thought much about the lesser parts of the language.

Until I started to learn other languages as well, that is.

In May of 2010 I learned Objective-C, to create iPhone- and iPad apps. I like the fact that everything is very strict: you always know precisely what types of arguments a methods expects, and what the return value will be. I spend a lot less time looking at source code or documentation; Xcode's autocompletion will tell me in detail how I should call a function and what I'll get back. Then again, writing separate header- and implementation files is not on my list of things I like to day all day long.

A few week ago I bought a book on Ruby. Mainly because it looked like a very nice language, but also in great part because of MacRuby and its Cocoa bindings. My suspicion was correct: Ruby is a very nice language. In fact, in many ways it looks much friendlier and more logical than Python. Of course also this language has its quirks, things that would bother me.

I then began to wonder what my ideal language would look like, if I could design my own. One part Ruby, one part Python, sprinkle with the best parts of Objective-C, and finish with the outstanding documentation of PHP. It would probably have the following characteristics:

* There should be one —and preferably only one— obvious way to do it
* Everything is an object
* Significant whitespace but with curly braces: easy to see where a function or block ends, but will enforce correct indentation (i.e. will not run when code inside a block is not indented correctly)
* [Static](http://en.wikipedia.org/wiki/Type_system#Static_typing), [Strong](http://en.wikipedia.org/wiki/Strong_typing) and [Duck](http://en.wikipedia.org/wiki/Duck_typing) typing
* Add methods to existing classes (even internal ones) like in Ruby or Objective-C's categories.
* Unicode everywhere
* Function names and variables may end with punctuation codes ? and !. The question marks makes it clear it's a function that returns a Bool. The exclamation mark indicates the function should be used with care, for example because it modifies a variable in place (instead of returning a modified copy).
* Very few global functions, prefer methods on internal classes
* Keyword arguments
* Visibility: public, protected, private
* Blocks like in Ruby or Objective-C
* Multiple inheritance
* Decorators
* Only one way to add comments: the # sign. Multi-line comment syntax like `/* */` is ugly.
* Global variables [like in Python](http://stackoverflow.com/questions/423379/global-variables-in-python)
* Python's `from ... import ...` and `import ...`, giving you great control over namespaces
* But not the `__init__.py` files!
* Enforced case convention, no more mixed styles from different programmers working on the same project:
	* CONSTANTS
	* ClassNames
	* variable_names
	* function_names()

Let's start with some basic hypothetical code examples.

## Strings
```text
# variable_type variable_name = statement
String greeting = 'Hello, world'
String another_string = String.new('Also a string')
print greeting # 'Hello, world'
greeting.class # String
greeting.length # length is a property, not a function

# Single quoted strings are "raw" strings. Double quoted string can
# contain special escape sequences. Single quoted string are a
# little bit more efficient if you don't need those sequences.
print "hello\tworld" # 'hello	world'
print 'hello\tworld' # 'hello\tworld'

# String interpolating is not supported, since this often leads to
# unreadable strings. Use string formatting instead:
print 'Hello, %s'.format('World')
print 'Name: %(name)s, age: %(id)d'.format(name='Kevin', age=29)
```

## Numbers
```text
Int one = 1
Float third = 0.3
print one # 1
String one_string = one.to_s()
print one_string # '1'
```

## Lists and ranges
```text
List my_list = ['a', 1, another_object]
my_list.length
print my_list[0]

List my_range = [1..3]
# this includes the end number, so the same as [1, 2, 3]

# You can create a list with an infinite length.
# This can be used in place of the while(True) syntax
# seen in other languages (see also Enumeration, below)
List my_infinite range = [0..]

# Since all lists are (yield) generators, this infinite
# list doesn't use infinite memory.
```

## Hashes
```text
Hash my_hash = {'food':'apple', 'color':'green', 'price':12}
print my_hash['food']

key = 'color'
print my_hash[key]
```

## Functions
```text
# (return_type) function_name(arguments) { code }
(Int) make_sum(Int x, Int y) {
    return x + y
}

Int the_sum = make_sum(x=123, y=456)

# Order of arguments doesn't matter, as long as all
# the required arguments are given.
# Note: Void is the same as Null or None in other languages.
(Void) print_line(String name='world', String greeting) {
    print '%s, %s!'.format(greeting, name)
}

print_line(greeting='Hello') # print "Hello, world!"

# If a function has no arguments, you can't leave
# out the parenthesis (like you can in Ruby)
a_function()

# Lastly, if a function doesn't specifically return
# something, it doesn't. Unlike Ruby, where the
# last statement is returned.
```

## Decorators
```text
@login_required()
(String) get_username() {
    return self.user.username
}
```

## Flow control
```text
# Empty string, list, hash and zero are all False.
if variable == True {
    # do stuff
} else {
    # something else
}

# Triple equation marks checks if it's the same type as well as value
if 1234 === True {
    # this will never be reached since an int is not a boolean
}

variable.switch() {
    case 'one' {
        # the value of variable equals 'one'
    }

    case 'two' {
        # the value of variable equals 'two'
    }

    default {
        # the value of variable is neither 'one' or 'two'
    }
}
```

## Classes
```text
class MyClass(Superclass) {
    String my_variable

    (MyClass) new(String variable) {
        # This is the default constructor or initializer.
        # If we subclass/override it, we should call the super class:
        self = super.new()

        # Do custom initializing, set instance variables, etc
        self.my_variable = variable

        # new() should always return self
        return self
    }

    (String) to_s() {
        return '<MyClass %s>'.format(self.my_variable)
    }
}

# Extend existing classes by reopening them. After we do this,
# all strings will know how to greet.
class String {
    (Void) protected greet() {
        print 'Hello, %s'.format(self)
    }
}

# Overwrite a function in an existing class. Great if you use third
# party software that is perfect except for that one function...
class User {
    (Bool) authenticated?() {
        # The way you want it to work...
    }
}
```

## Symbols
```text
# Symbols are immutable, super lightweight strings. They are created
# with backticks.
Symbol sym = `this is a symbol`

# You can use this when you're only interested in the value of a string
# and don't need any of the String methods. A good use is for selectors
# like this:
object.responds_to?(`do_stuff`)

# You only care about the value of the string, you don't need to trim it,
# make it uppercase, count the letters, etc.
# This also works, but creating an instance of a String and passing
# it around is overkill:
my_list.responds_to?('do_stuff')

# Basically, the only thing they know is how is print themselves
print `oh lala`

`oh lala`.upper() # fail! need to convert to a string first
`oh lala`.to_s().upper()

# Since symbols save memory, they are recommended when you'd use a
# string only as identifier:
Hash my_better_hash = {`food`:'apple', `color`:'green', `price`:12}
print my_better_hash[`food`]
```

Note to self: not really sure about this syntax. Especially in the hash example the mixed use of backticks and single quotes is ugly and confusing. Still better than Ruby's :symbol syntax though, again especially when combined with hashes.

## Blocks
```text
# Blocks are anonymous (nameless) functions. Formal syntax:
# (return type) block_name = ^(arguments) { code }

(Int) my_block = ^(Int number) {
    return number * 7
}

print "%d".format(my_block(3))

# Of course, this was not much different from creating a normal
# function. Comparison:
# (Int) my_function(Int number) {
# 	return number * 7
# }

# The real power of blocks is from using them directly as function
# arguments:

my_array.custom_sort(^(Object first_item, Object second_item) {
    return first_item < second_items
})

# A block with no arguments drops the parenthesis: ^{}
3.times(^{print 'hooray!'})
```

## Enumeration
```text
# Enumeration is done with blocks.

[1..3].each(^(Int i) {
    print i
}

# Break out of a loop by returning
[0..].each(^(Int i) {
    print i

    if i == 3 {
        return
    }
}
# prints 0, 1, 2 and 3, then exists the loop

my_list.each(^(Object item) {
    print item
}

my_hash.each(^(String k, Object v) {
    print '%(key)s = %(value)s'.format(key=k, value=v)
}
```

As you can see, most of the syntax is a blend of Ruby and Python, but with static typing and curly braces. Of course this is not a complete description of a language, but the general feel and syntax should be clear.

# Why not just use...

...Ruby?

* I don't like the `do` / `end` block syntax with the vertical bars
* Multiple ways to do stuff. I like my language explicit, not implicit.
* Whitespace is not significant, correct indentation is not enforced
* No multiple inheritance, no decorators
* `@instance_variable` and `@@class_variable`. I think `self.instance_variable` is much cleaner.
* `$global_variable`
* Parenthesis and return statement are not required but implied. Again: I like explicit much better.
* The `=>` syntax for hashes

...or Python?

* All those annoying underscores in function names
* The `__init__.py` files. It's just ugly!
* Not everything is an object, too many global functions (i.e. `len(list)` instead of `list.len()`)
* Ugly syntax bits like the lambda functions and the call to a superclass function: `super(MyClass, self).__init__(*args, **kwargs))`
* Dictionaries are unsorted
* `self` as the first argument of each and every method
* No `switch` statement
* No visibility (public, protected, private)
* No easy way to extend existing classes, or overwrite functions in them
* `' '.join(list)` instead of `list.join(' ')` - it's just backwards!

This repository contains a simple reproduction of an issue when
pattern matching a sealed class in Dart against a pattern of
another sealed class that it can never match.

The complete example is located in [bin/main.dart](bin/main.dart).

# What is the problem?

Assuming there are two sealed classes `sealed class Foo` and `sealed class Bar`,
where no implementation of `Foo` implements or extends `Bar` and vice versa.

```dart
sealed class Foo {}

class FooImpl extends Foo {}

sealed class Bar {}

class BarImpl extends Bar {}
```

When pattern matching a value that is known to be of type `Foo` at compile time
against a pattern of `Bar()`, it should be clear, that this pattern match
will never succeed.

```dart
switch (FooImpl()) {
  // ❌ does not cause an error or a warning like: pattern_never_matches_value_type
  case Bar():
    print('matched Bar()');
    break;
  
  case Foo():
    print('matched Foo()');
    break;
}
```

The problem is, that no warning is shown, neither by the compiler nor the analyzer,
explaining that the pattern can never match the type.
I.e. running `dart analyze` on this project causes the analyzer to report:
`No issues found!`

It is possible to get the desired warning
by adding a `final` modifier to all implementations of `Foo`.

```diff
sealed class Foo {}

- class FooImpl extends Foo {}
+ final class FooImpl extends Foo {}

sealed class Bar {}

class BarImpl extends Bar {}
```

Now trying to pattern match on `Bar()` correctly yields an analyzer warning `pattern_never_matches_value_type`.

```dart
switch (FooImpl()) {
  // ✅ correctly causes warning: pattern_never_matches_value_type
  case Bar():
    print('matched Bar()');
    break;
  
  case Foo():
    print('matched Foo()');
    break;
}
```

However, assuming that `sealed` classes are effectively `final`, it should be possible for the
compiler/analyzer to figure out, that a value of type `Foo` can never match the pattern `Bar()` even if the implementations
of `Foo` are not explicitly marked as `final`.

# Why does it matter?

I did a rather large change on a big project,
replacing a `sealed class FooFromApi` in many (but not all) cases with another `sealed class FooFromDatabase`.

Unfortunately there was no support by the analyzer/compiler that helped finding all the cases
where patterns were still trying to match `FooFromApi(...)`, that should now instead match `FooFromDatabase(...)`.
In the end, I overlooked one such pattern that was not covered by tests, which then introduced a bug
into the application logic.

Since the project uses [Freezed](https://github.com/rrousselGit/freezed) to generate most of the
data classes, it is not possible to make the implementations of the `sealed` classes `final`.
Thus it would be really helpful if the analyzer/compiler could take care of this, since the usage
of Freezed is very common in Flutter/Dart projects these days.

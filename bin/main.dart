sealed class Foo {}

class FooImpl extends Foo {}

sealed class Bar {}

class BarImpl extends Bar {}

void main() {
  switch (FooImpl()) {
    // ❌ does not cause any warning or error
    case Bar():
      print('matched Bar()');
      break;

    case Foo():
      print('matched Foo()');
      break;
  }
}

Well, the most unfortunate thing about monads is actually their name. Because
of that, I will actually be referring to monads as _effects_.

So, what are effects? Effects are the ways a piece of code can interact with the
real world. Some examples of things I'll refer to as effects:
- Throwing exceptions
- Printing to the screen
- Checking if a file exists
- Cancelling an asynchronous task

In what us functional freaks refer to as "pure code", all effects have to be
done in a roundabout way, by representing effects as types, which we use as the
return type of a function. You can think of a function as _returning_ the effect
instead of actually doing it.

```csharp
abstract class Result<T> {
    // Reading the output.
    public abstract T? GetOk();
    public abstract Exception? GetException();
}

class Ok<T> : Result<T> {
    T ret;
    // ...
}

class ThrowException<T> : Result<T> {
    Exception e;
    // ...
}

// Here the function doesn't actually throw the exception in the literal sense,
// it just returns the action of throwing.
Result<int> Divide(int a, int b) {
    if (b == 0) {
        return new Ok(a / b);
    } else {
        return new ThrowException(new InvalidArgumentException("nooo don't divide by zero!"))
    }
}
```

We have made `Divide` pure!

---

All effect types can implement the following interface:

```csharp
interface Effect<T> {
    // Just return the value, without doing anything else.
    // (Interfaces can't actually have static methods, but go along with it)
    static Effect<T> Return(T val);
    // Run the function on the output.
    Effect<U> AndThen<T, U>(Func<T, Effect<U>> f);
}

// Example implementation

abstract class Result<T> : Effect<T> {
    public abstract T? GetOk();
    public abstract Exception? GetException();
    // Here comes the interface
    public static Result<T> Return(T val) {
        return new Ok(val);
    }
    public Effect<U> AndThen(Func<T, Effect<U>> f) {
        if (GetOk() is T ok) {
            return f(ok);
        } else {
            // When an exception is thrown, the next action `f` is not ran.
            return this;
        }
    }
}
```

(Note that this isn't actually a valid interface, so we can't actually represent
an effect with an interface. Effects are implemented via something called Type
Classes, in languages that have those)

Why `Return` and `AndThen`? Why this interface specifically?
`Return` let's us do "null" effects which don't do anything, and that's
important. Every effect can do that. And the `AndThen` let's do actions one
after another, and potentially skip the second action, or run it twice, or send
it to an asynchronous thread, or log the output to a file. These two functions
are the base things that all effects have, and if you something more specific,
you have other kinds of interfaces which inherit from effect ([Varieties of Monads](https://lean-lang.org/doc/reference/latest/Functors___-Monads-and--do--Notation/Varieties-of-Monads/))

---

This effect interface let's us be generic over the Effect of a function, letting
users switch it out for their own thing. Have you ever wanted to map over a
list, but pause the execution in the middle?

```csharp
E<List<U>> MapList<E, T, U>(List<T> list, Func<T, E<T>> mapping, int start = 0)
where for<T> E<T>: Effect<T>
{
    if (list.Count() <= start) return E.Return(new List());
    var item = list[start];
    return mapping(item).AndThen(mappedItem => {
        return MapList(list, mapping, start + 1).AndThen(mappedRestOfList => {
            var l = new T[] { mappedItem }
                .Concat(mappedRestOfList)
                .toList();
            return E.Return(l);
        });
    });
}
```

This imperative style of syntax makes writing effectful code like this very
verbose, but languages with effect types usually have something called "do
notation", which lets you use `return` as short for `return E.Return(..)` and `<-` as
short for `AndThen`.

```csharp
E<List<U>> MapList<E, T, U>(List<T> list, Func<T, E<T>> mapping, int start = 0)
where for<T> E<T>: Effect<T>
{
    if (list.Count() <= start) do return new List();
    do {
        var item = list[start];
        var mappedItem <- mapping(item);
        var mappedRestOfList <- MapList(list, mapping, start + 1);
        return new T[] { mappedItem }
            .Concat(mappedRestOfList)
            .toList();
    }
}
```

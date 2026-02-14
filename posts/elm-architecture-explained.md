# The Elm Architecture Explained

The Elm Architecture (TEA) is a simple pattern for architecting webapps. It's the backbone of all Elm applications.

## The Three Parts

### Model
The state of your application. It's just data!

```elm
type alias Model =
    { counter : Int
    , text : String
    }
```

### Update
A function that takes a message and the current model, and returns a new model.

```elm
update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            { model | counter = model.counter + 1 }
        Decrement ->
            { model | counter = model.counter - 1 }
```

### View
A function that takes the model and returns HTML.

```elm
view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ text "-" ]
        , text (String.fromInt model.counter)
        , button [ onClick Increment ] [ text "+" ]
        ]
```

## Why It's Elegant

1. **Simple**: Just three concepts to understand
2. **Testable**: Pure functions are easy to test
3. **Maintainable**: Clear separation of concerns
4. **Scalable**: Works for small and large applications

The Elm Architecture inspired Redux, Flux, and many other state management patterns in JavaScript. Once you understand it, you'll see its influence everywhere!

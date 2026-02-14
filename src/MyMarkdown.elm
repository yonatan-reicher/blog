module MyMarkdown exposing
    ( Markdown
    , Error
    , parse
    , toHtml
    )

import Markdown as M
import Html exposing (Html)
import Regex


{-|
Parsing and rendering Markdown content for blog posts.
Note that this is mostly an abstraction layer over a library.
-}


{-
## Choosing a markdown library
A number of Elm libraries exist for parsing Markdown:
1. [dillonkearns](https://package.elm-lang.org/packages/dillonkearns/elm-markdown/latest/)
2. [elm-explorations](https://package.elm-lang.org/packages/elm-explorations/markdown/latest/)
3. [jxxcarlson](https://package.elm-lang.org/packages/jxxcarlson/elm-markdown/latest/)
4. [pablohirafuji](https://package.elm-lang.org/packages/pablohirafuji/elm-markdown/latest/)

I'll just use the elm-explorations one because it is the simplest.
-}

type Markdown
    = Markdown { content : Html Never }


type alias Error = Never


startsWithLetter : String -> Bool
startsWithLetter line =
    case String.uncons line of
        Nothing -> False
        Just (c, _) -> Char.isAlpha c


startsWithLink : String -> Bool
startsWithLink line =
    let r =
            Regex.fromString "^\\[.*\\]\\(.*\\)"
            -- TODO: Would probably be better if we failed here, right?
            -- Maybe this is a case for exceptions and not result types..?
            -- Too bad we don't have that!
            |> Maybe.withDefault Regex.never
    in
    Regex.contains r line


isTextLine : String -> Bool
isTextLine line =
    not (String.isEmpty line)
    && (  startsWithLetter line
       || startsWithLink line
       )


removeBadNewLines : String -> String
removeBadNewLines text =
    text
    |> String.lines
    |> List.foldr (\line string ->
            let sep =
                    if isTextLine line && isTextLine string then
                        " "
                    else
                        "\n" in
            line ++ sep ++ string
        )
        ""


parse : String -> Result Error Markdown
parse text =
    text
    |> removeBadNewLines
    |> M.toHtmlWith
        { githubFlavored = Just { tables = True, breaks = True }
        , defaultHighlighting = Nothing
        , sanitize = False
        , smartypants = True
        }
        []
    |> \content -> Markdown { content = content }
    |> Ok


toHtml : Markdown -> Html msg
toHtml (Markdown { content }) =
    content
    |> Html.map never

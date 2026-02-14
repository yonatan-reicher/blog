port module Ports exposing (onViewPost)

{- JavaScript interop for syntax highlighting.
Call onViewPost after rendering post content.
-}

{-| Trigger syntax highlighting in JavaScript, load script tags, and fix some
certain things. -}
port onViewPost : () -> Cmd msg


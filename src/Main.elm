module Main exposing (main)

import Array exposing (Array)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Parser
import Html.Parser.Util
import Http
import Json.Decode as D
import Url exposing (Url)
import Url.Parser exposing (Parser, (<?>))
import Url.Parser.Query

import MyMarkdown as Markdown
import Ports


-- MAIN

main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


-- MODEL

type alias Flags = { userAgent : String }

type alias Model =
    { route : Route
    , posts : LoadResult Posts
    , currentPost : Maybe (LoadResult PostContent)
    , key : Nav.Key
    , isPhone : Bool
    }

type Route
    = Home
    | PostPage String
    | BadRoute

-- Represents the state of an asynchronous data fetch
-- Use this instead of Result when you need to track loading state
type LoadResult a 
    = Loading
    | Loaded a
    | LoadError Http.Error

type alias Content = String

type alias Post =
    { slug : String
    , title : String
    , date : String
    , category : String
    , excerpt : String
    , fileType : FileType
    }

type alias Posts = Array Post

type FileType
    = Html
    | Markdown

type alias PostContent =
    { post : Post
    , content : String
    }

loadResultFromResult : Result Http.Error a -> LoadResult a
loadResultFromResult result =
    case result of
        Ok value ->
            Loaded value
        Err error ->
            LoadError error

findPostBySlug : LoadResult Posts -> String -> Maybe Post
findPostBySlug loadResult slug =
    case loadResult of
        Loaded posts ->
            Array.toList posts
                |> List.filter (\p -> p.slug == slug)
                |> List.head
        _ ->
            Nothing

postUrl : String -> String
postUrl slug = "?post=" ++ slug

homeUrl : String
homeUrl = "?"

isPhone : String -> Bool
isPhone userAgent =
    let 
        phoneUserAgents =
            [ "android"
            , "webos"
            , "iphone"
            , "ipad"
            , "ipod"
            , "blackberry"
            , "iemobile"
            , "opera mini"
            , "windows phone"
            ]
        lowerUserAgent = String.toLower userAgent
    in
    List.any (\agent -> String.contains agent lowerUserAgent) phoneUserAgents


-- INIT

fetchPosts : Cmd Msg
fetchPosts =
    let
        decoder =
            D.array <| D.map6 Post
                (D.field "slug" D.string)
                (D.field "title" D.string)
                (D.field "date" D.string)
                (D.field "category" D.string)
                (D.field "excerpt" D.string)
                (D.field "fileType" fileTypeDecoder)
        fileTypeDecoder =
            D.string |> D.andThen (\s ->
                case s of
                    "html" -> D.succeed Html
                    "md" -> D.succeed Markdown
                    _ -> D.fail <| "'" ++ s ++ "' is not a valid file type, should be either 'html' or 'markdown'")
    in
    Http.get
        { url = "posts.json"
        , expect = Http.expectJson GotPosts decoder
        }

init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init { userAgent } url key =
    let initialModel =
            { route = Home
            , posts = Loading
            , currentPost = Nothing
            , key = key
            , isPhone = isPhone userAgent
            }
    in
    initialModel
    |> update (UrlChanged url)
    |> \(model, cmd) -> (model, Cmd.batch [ cmd, fetchPosts ])

-- URL PARSING

parseUrl : Url -> Route
parseUrl url =
    let base =
            Url.Parser.oneOf
                [ Url.Parser.map () Url.Parser.top
                , Url.Parser.map (\_ -> ()) Url.Parser.string
                ]
        query = Url.Parser.Query.string "post"
        parser = Url.Parser.map (\_ slug -> slug) <| base <?> query
    in
    case Url.Parser.parse parser url of
        Just (Just slug) -> PostPage slug
        Just Nothing -> Home
        Nothing -> BadRoute


-- UPDATE

type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | LoadedPost (Result Http.Error String)
    | GotPosts (Result Http.Error Posts)
    | NavigateToPost String
    | NavigateToHome

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked (Browser.Internal url) ->
            ( model, Cmd.none )

        LinkClicked (Browser.External href) ->
            ( model, Nav.load href )

        UrlChanged url ->
            let
                route = parseUrl url
            in
            case route of
                PostPage slug ->
                    case findPostBySlug model.posts slug of
                        Just post ->
                            ( { model | route = route, currentPost = Just Loading }
                            , loadPostWithFormat post
                            )
                        Nothing ->
                            ( { model | route = route }, Cmd.none )
                _ ->
                    ( { model | route = route }, Cmd.none )
        
        LoadedPost (Ok content) ->
            case model.route of
                PostPage slug ->
                    case findPostBySlug model.posts slug of
                        Just post ->
                            ( { model 
                              | currentPost = Just (Loaded { post = post, content = content })
                              }
                            , Ports.onViewPost ()
                            )
                        Nothing ->
                            ( model, Cmd.none )
                _ ->
                    ( model, Cmd.none )
        
        LoadedPost (Err err) ->
            ( { model | currentPost = Just (LoadError err) }, Cmd.none )
        
        NavigateToPost slug ->
            ( model
            , Nav.pushUrl model.key (postUrl slug)
            )
        
        NavigateToHome ->
            ( model
            , Nav.pushUrl model.key homeUrl
            )

        GotPosts result ->
            case result of
                Ok posts ->
                    let
                        sortedPosts =
                            posts
                            |> Array.toList
                            |> List.sortBy (\post -> post.date)
                            |> List.reverse
                            |> Array.fromList
                        
                        newModel =
                            { model | posts = Loaded sortedPosts }
                        
                        -- If we're on a post page, try to load that post now
                        (updatedModel, cmd) = case model.route of
                            PostPage slug ->
                                case findPostBySlug newModel.posts slug of
                                    Just post ->
                                        ( { newModel | currentPost = Just Loading }
                                        , loadPostWithFormat post
                                        )
                                    Nothing ->
                                        ( newModel, Cmd.none )
                            _ ->
                                ( newModel, Cmd.none )
                    in
                    ( updatedModel, cmd )
                Err error ->
                    ( { model | posts = LoadError error }
                    , Cmd.none
                    )

-- HTTP

loadPostWithFormat : Post -> Cmd Msg
loadPostWithFormat post =
    let
        extension = 
            case post.fileType of
                Html -> ".html"
                Markdown -> ".md"
    in
    Http.get
        { url = "posts/" ++ post.slug ++ extension
        , expect = Http.expectString LoadedPost
        }


-- VIEW

view : Model -> Browser.Document Msg
view model =
    { title = pageTitle model
    , body = 
        [ div [ class "container" ]
            [ viewHeader
            , viewContent model
            , viewFooter
            ]
        ]
    }

pageTitle : Model -> String
pageTitle { currentPost } =
    case currentPost of
        Just (Loaded { post }) -> "Thoughts | " ++ post.title
        Just Loading -> "Thoughts | …"
        Just (LoadError _) -> "Thoughts | Error!"
        Nothing -> "Thoughts"

viewHeader : Html Msg
viewHeader =
    header [ class "header" ]
        [ h1 [ class "site-title" ] [ text "Thoughts" ]
        , nav [ class "nav" ]
            [ a [ href homeUrl, onClick NavigateToHome ] [ text "Home" ]
            -- , a [ href "?page=about", onClick NavigateToAbout ] [ text "About" ]
            ]
        ]

viewContent : Model -> Html Msg
viewContent model =
    main_ [ class "content" ]
        [ case model.route of
            Home ->
                case model.posts of
                    Loaded posts ->
                        viewHomePage posts
                    Loading ->
                        div [ class "loading" ] [ text "Loading posts..." ]
                    LoadError _ ->
                        div [ class "error" ] [ text "Failed to load posts" ]
            PostPage slug ->
                viewPostPage model
            BadRoute ->
                div [ class "not-found" ]
                    [ h2 [] [ text "404 - Page Not Found" ]
                    , p [] [ text "The page you're looking for doesn't exist." ]
                    , a [ href homeUrl, onClick NavigateToHome ] [ text "Go home" ]
                    ]
        ]

viewHomePage : Posts -> Html Msg
viewHomePage posts =
    div [ class "home" ]
        [ h2 [] [ text "Recent Posts" ]
        , div [ class "posts-list" ] (Array.map viewPostCard posts |> Array.toList)
        ]

viewPostCard : Post -> Html Msg
viewPostCard post =
    article [ class "post-card" ]
        [ div [ class "post-meta" ]
            [ span [ class "post-category" ] [ text post.category ]
            , span [ class "post-date" ] [ text post.date ]
            ]
        , h3 [ class "post-title" ]
            [ a 
                [ href (postUrl post.slug)
                , onClick (NavigateToPost post.slug)
                ] 
                [ text post.title ]
            ]
        , p [ class "post-excerpt" ] [ text post.excerpt ]
        ]

viewPostPage : Model -> Html Msg
viewPostPage model =
    case model.currentPost of
        Just (Loaded postContent) ->
            article [ class "post" ]
                [ div [ class "post-header" ]
                    [ h2 [] [ text postContent.post.title ]
                    , div [ class "post-meta" ]
                        [ span [ class "post-category" ] [ text postContent.post.category ]
                        , span [ class "post-date" ] [ text postContent.post.date ]
                        ]
                    ]
                , div [ class "post-content" ] 
                    [ renderPostContent postContent ]
                ]
        Just (LoadError err) ->
            div [ class "error" ] 
                [ text "Failed to load post: "
                , text (httpErrorToString err)
                ]
        Just Loading ->
            div [ class "loading" ] [ text "Loading post..." ]
        Nothing ->
            div [ class "error" ] [ text "No post selected" ]

renderPostContent : PostContent -> Html Msg
renderPostContent postContent =
    case postContent.post.fileType of
        Html ->
            -- Parse and render HTML
            case Html.Parser.run postContent.content of
                Ok nodes ->
                    div [] (Html.Parser.Util.toVirtualDom nodes)
                
                Err _ ->
                    div [ class "error" ] 
                        [ text "Failed to parse HTML content" ]
        Markdown ->
            -- Render markdown
            case Markdown.parse postContent.content of
                Ok markdown ->
                    Markdown.toHtml markdown
                
                Err _ ->
                    div [ class "error" ] 
                        [ text "Failed to parse markdown content" ]

httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url -> "Bad URL: " ++ url
        Http.Timeout -> "Request timeout"
        Http.NetworkError -> "Network error"
        Http.BadStatus status -> "Bad status: " ++ String.fromInt status
        Http.BadBody body -> "Bad body: " ++ body



viewFooter : Html Msg
viewFooter =
    footer [ class "footer" ]
        [ p [] 
            [ text "Thoughts. Built with "
            , a [ href "https://github.com/yonatan-reicher/blog" ] [ text "Love" ]
            , text "."
            ]
        ]


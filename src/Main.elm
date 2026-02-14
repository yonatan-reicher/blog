module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, (<?>))
import Url.Parser.Query as Query
import Browser.Navigation as Nav
import Markdown
import Html.Parser
import Html.Parser.Util


-- MAIN

main : Program () Model Msg
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

type alias Model =
    { page : Page
    , posts : List Post
    , currentPost : Maybe PostContent
    , loadingPost : Bool
    , key : Nav.Key
    }

type Page
    = Home
    | PostPage String
    | About
    | NotFound

type alias Post =
    { slug : String
    , title : String
    , date : String
    , category : String
    , excerpt : String
    , format : String  -- "markdown" or "html"
    }

type alias PostContent =
    { post : Post
    , content : String
    }


-- INIT

init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        page = parseUrl url
        initialModel =
            { page = page
            , posts = samplePosts
            , currentPost = Nothing
            , loadingPost = False
            , key = key
            }
    in
    case page of
        PostPage slug ->
            let
                maybePost = List.filter (\p -> p.slug == slug) samplePosts
                    |> List.head
            in
            case maybePost of
                Just post ->
                    ( { initialModel | loadingPost = True }
                    , loadPostWithFormat post
                    )
                Nothing ->
                    ( initialModel, Cmd.none )
        _ ->
            ( initialModel, Cmd.none )


-- URL PARSING

parseUrl : Url -> Page
parseUrl url =
    let
        queryParser =
            Parser.top <?> Query.string "page"
    in
    case Parser.parse queryParser url of
        Just (Just "about") ->
            About
        Just (Just slug) ->
            if String.startsWith "post/" slug then
                PostPage (String.dropLeft 5 slug)
            else
                NotFound
        Just Nothing ->
            Home
        Nothing ->
            Home


-- SAMPLE DATA

samplePosts : List Post
samplePosts =
    [ { slug = "welcome-to-my-blog"
      , title = "Welcome to My Blog"
      , date = "2024-02-14"
      , category = "Life"
      , excerpt = "Starting a new journey of writing about code, computer science, and life."
      , format = "markdown"
      }
    , { slug = "elm-architecture-explained"
      , title = "The Elm Architecture Explained"
      , date = "2024-02-10"
      , category = "Code"
      , excerpt = "A deep dive into The Elm Architecture and why it's so elegant."
      , format = "markdown"
      }
    , { slug = "algorithms-for-beginners"
      , title = "Algorithms for Beginners"
      , date = "2024-02-05"
      , category = "CS"
      , excerpt = "Understanding the basics of algorithms and data structures."
      , format = "markdown"
      }
    , { slug = "html-post-example"
      , title = "HTML Post Example"
      , date = "2024-02-15"
      , category = "Code"
      , excerpt = "An example post written in pure HTML with custom styling and interactive elements."
      , format = "html"
      }
    ]


-- UPDATE

type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url
    | LoadedPost (Result Http.Error String)
    | NavigateToPost String
    | NavigateToHome
    | NavigateToAbout

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked (Browser.Internal url) ->
            ( model, Cmd.none )
        
        LinkClicked (Browser.External href) ->
            ( model, Cmd.none )
        
        UrlChanged url ->
            let
                page = parseUrl url
            in
            case page of
                PostPage slug ->
                    let
                        maybePost = List.filter (\p -> p.slug == slug) model.posts
                            |> List.head
                    in
                    case maybePost of
                        Just post ->
                            ( { model | page = page, loadingPost = True }
                            , loadPostWithFormat post
                            )
                        Nothing ->
                            ( { model | page = page }, Cmd.none )
                _ ->
                    ( { model | page = page }, Cmd.none )
        
        LoadedPost (Ok content) ->
            case model.page of
                PostPage slug ->
                    let
                        postData = List.filter (\p -> p.slug == slug) model.posts
                            |> List.head
                    in
                    case postData of
                        Just post ->
                            ( { model 
                              | currentPost = Just { post = post, content = content }
                              , loadingPost = False
                              }
                            , Cmd.none
                            )
                        Nothing ->
                            ( { model | loadingPost = False }, Cmd.none )
                _ ->
                    ( { model | loadingPost = False }, Cmd.none )
        
        LoadedPost (Err _) ->
            ( { model | loadingPost = False }, Cmd.none )
        
        NavigateToPost slug ->
            ( model
            , Nav.pushUrl model.key ("?page=post/" ++ slug)
            )
        
        NavigateToHome ->
            ( model
            , Nav.pushUrl model.key "?"
            )
        
        NavigateToAbout ->
            ( model
            , Nav.pushUrl model.key "?page=about"
            )


-- HTTP

loadPostWithFormat : Post -> Cmd Msg
loadPostWithFormat post =
    let
        extension = if post.format == "html" then ".html" else ".md"
    in
    Http.get
        { url = "posts/" ++ post.slug ++ extension
        , expect = Http.expectString LoadedPost
        }


-- VIEW

view : Model -> Browser.Document Msg
view model =
    { title = pageTitle model.page
    , body = 
        [ div [ class "container" ]
            [ viewHeader
            , viewContent model
            , viewFooter
            ]
        ]
    }

pageTitle : Page -> String
pageTitle page =
    case page of
        Home ->
            "Home - My Code Blog"
        PostPage _ ->
            "Post - My Code Blog"
        About ->
            "About - My Code Blog"
        NotFound ->
            "Not Found - My Code Blog"

viewHeader : Html Msg
viewHeader =
    header [ class "header" ]
        [ h1 [ class "site-title" ] [ text "Code, CS & Life" ]
        , nav [ class "nav" ]
            [ a [ href "?", onClick NavigateToHome ] [ text "Home" ]
            , a [ href "?page=about", onClick NavigateToAbout ] [ text "About" ]
            ]
        ]

viewContent : Model -> Html Msg
viewContent model =
    main_ [ class "content" ]
        [ case model.page of
            Home ->
                viewHomePage model.posts
            PostPage slug ->
                viewPostPage model
            About ->
                viewAboutPage
            NotFound ->
                viewNotFoundPage
        ]

viewHomePage : List Post -> Html Msg
viewHomePage posts =
    div [ class "home" ]
        [ h2 [] [ text "Recent Posts" ]
        , div [ class "posts-list" ] (List.map viewPostCard posts)
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
                [ href ("?page=post/" ++ post.slug)
                , onClick (NavigateToPost post.slug)
                ] 
                [ text post.title ]
            ]
        , p [ class "post-excerpt" ] [ text post.excerpt ]
        ]

viewPostPage : Model -> Html Msg
viewPostPage model =
    if model.loadingPost then
        div [ class "loading" ] [ text "Loading post..." ]
    else
        case model.currentPost of
            Just postContent ->
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
            Nothing ->
                div [ class "error" ] [ text "Post not found" ]

renderPostContent : PostContent -> Html Msg
renderPostContent postContent =
    if postContent.post.format == "html" then
        -- Parse and render HTML
        case Html.Parser.run postContent.content of
            Ok nodes ->
                div [] (Html.Parser.Util.toVirtualDom nodes)
            
            Err _ ->
                div [ class "error" ] [ text "Failed to parse HTML content" ]
    else
        -- Render markdown
        Markdown.toHtmlWith 
            { githubFlavored = Just { tables = True, breaks = False }
            , defaultHighlighting = Nothing
            , sanitize = False
            , smartypants = True
            }
            []
            postContent.content

viewAboutPage : Html Msg
viewAboutPage =
    div [ class "about" ]
        [ h2 [] [ text "About Me" ]
        , p [] [ text "Welcome to my blog where I write about code, computer science, and life." ]
        , p [] [ text "This blog is built with Elm and hosted on GitHub Pages." ]
        ]

viewNotFoundPage : Html Msg
viewNotFoundPage =
    div [ class "not-found" ]
        [ h2 [] [ text "404 - Page Not Found" ]
        , p [] [ text "The page you're looking for doesn't exist." ]
        , a [ href "?", onClick NavigateToHome ] [ text "Go home" ]
        ]

viewFooter : Html Msg
viewFooter =
    footer [ class "footer" ]
        [ p [] [ text "© 2024 My Code Blog. Built with Elm." ]
        ]

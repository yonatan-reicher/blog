module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Parser
import Html.Parser.Util
import Http
import Markdown
import Url exposing (Url)
import Url.Parser exposing (Parser, (<?>))
import Url.Parser.Query


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

type alias Flags = { userAgent: String }

type alias Model =
    { route : Route
    , key : Nav.Key
    , posts : Maybe (List Post)
    , currentPost : Maybe PostContent
    , loadingPost : Bool
    , key : Nav.Key
    , isPhone : Bool
    }

type Route
    = Home
    | Post Post Content
    | NotFound Post

type alias Content = String

type alias Post =
    { slug : String
    , title : String
    , date : String
    , category : String
    , excerpt : String
    , fileType : FileType
    }

type FileType
    = Html
    | Markdown

type alias PostContent =
    { post : Post
    , content : String
    }


-- INIT

init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init { userAgent } url key =
    let page = parseUrl url
        initialModel =
            { page = page
            , posts = Nothing
            , currentPost = Nothing
            , loadingPost = False
            , key = key
            }
    in
    case page of
        Post post ->
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


{-

type Msg
    = UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | HomeMsg Home.Msg
    | BlogMsg Blog.Msg
    | ProjectsMsg Projects.Msg


type Route
    = HomeRoute
    | BlogRoute (Maybe String)
    | ProjectsRoute


routeParser : Url.Parser.Parser (Route -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.top |> Url.Parser.map HomeRoute
        , Url.Parser.s "blog"
          </> Url.Parser.oneOf
            [ Url.Parser.map Nothing Url.Parser.top
            , Url.Parser.map Just (Url.Parser.s "posts" </> Url.Parser.string)
            ]
          |> Url.Parser.map BlogRoute
        , Url.Parser.s "projects" |> Url.Parser.map ProjectsRoute
        ]


urlToRoute : Url.Url -> Maybe Route
urlToRoute url = 
    -- The RealWorld spec treats the fragment like a path.
    -- This makes it *literally* the path, so we can proceed
    -- with parsing as if it had been a normal path all along.
    -- Copied from elm-spa
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
    |> Url.Parser.parse routeParser


changeRoute : Maybe Route -> Model -> (Model, Cmd Msg)
changeRoute route model =
    case route of
        Nothing -> (model, Cmd.none)

        Just HomeRoute ->
            ({ model | page = Home () }
            , Cmd.none
            )

        Just (BlogRoute maybeFileName) ->
            Blog.init maybeFileName
            |> Tuple.mapFirst (\blogModel ->
                { model | page = Blog blogModel }
            )
            |> Tuple.mapSecond (Cmd.map BlogMsg)


        Just ProjectsRoute ->
            ({ model | page = Projects () }
            , Cmd.none
            )


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


phoneUserAgents : List String
phoneUserAgents =
    [ "Android"
    , "webOS"
    , "iPhone"
    , "iPad"
    , "iPod"
    , "BlackBerry"
    , "IEMobile"
    , "Opera Mini"
    , "windows phone"
    ]


isPhone : String -> Bool
isPhone userAgent =
    List.any (String.toLower >> String.contains (String.toLower userAgent)) phoneUserAgents


init : Flags -> Url.Url -> Nav.Key -> (Model, Cmd Msg)
init { userAgent } url key =
    Model key url (Home ()) (isPhone userAgent)
    |> changeRoute (urlToRoute url)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case (msg, model.page) of
        (UrlChanged url, _) ->
            changeRoute (urlToRoute url) model

        (LinkClicked request, _) ->
            case request of
                Browser.Internal url ->
                    (model, Nav.pushUrl model.key (Url.toString url))

                Browser.External href ->
                    (model, Nav.load href)

        (HomeMsg homeMsg, Home homeModel) ->
            Home.update homeMsg homeModel
            |> Tuple.mapBoth
                (\newHomeModel -> { model | page = Home newHomeModel })
                (Cmd.map HomeMsg)

        (HomeMsg _, _) -> (model, Cmd.none)

        (BlogMsg blogMsg, Blog blogModel) ->
            Blog.update blogMsg blogModel
            |> Tuple.mapBoth
                (\newBlogModel -> { model | page = Blog newBlogModel })
                (Cmd.map BlogMsg)

        (BlogMsg _, _) -> (model, Cmd.none)

        (ProjectsMsg projectsMsg, Projects projectsModel) ->
            Projects.update projectsMsg projectsModel
            |> Tuple.mapBoth
                (\newProjectsModel -> { model | page = Projects newProjectsModel })
                (Cmd.map ProjectsMsg)

        (ProjectsMsg _, _) -> (model, Cmd.none)


view : Model -> Browser.Document Msg
view model =
    model
    |> viewContent
    |> mapDocumentBody (\content ->
        [ navbar
            { direction = getNavbarDir model
            , onTopOf = content
            }
        ]
    )


getNavbarDir : Model -> Navbar.NavbarDir
getNavbarDir model =
    if model.isPhone then Navbar.Horizontal else Navbar.Vertical


mapDocumentBody : (List (Html a) -> List (Html b)) -> Document a -> Document b
mapDocumentBody f { title, body } =
    { title = title
    , body = f body
    }


viewContent : Model -> Document Msg
viewContent model =
    case model.page of
        Home homeModel ->
            Home.view homeModel
            |> mapDocument HomeMsg

        Blog blogModel ->
            { title = "Jonathan Reicher | Blog"
            , body =
                [ Blog.view blogModel
                  |> Html.map BlogMsg
                ]
            }

        Projects projectsModel ->
            Projects.view projectsModel
            |> mapDocument ProjectsMsg


mapDocument : (a -> b) -> Document a -> Document b
mapDocument f { title, body } =
    { title = title
    , body = List.map (Html.map f) body
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        Home homeModel ->
            Home.subscriptions homeModel
            |> Sub.map HomeMsg

        Blog _ ->
            Sub.none

        Projects projectsModel ->
            Projects.subscriptions projectsModel
            |> Sub.map ProjectsMsg

-}

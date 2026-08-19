module Main exposing (main)

import Browser as B
import Browser.Dom as BD
import Browser.Navigation as BN
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD
import Task
import Url exposing (Url)

import Backend exposing (Entry, EntryId(..))
import Acadia.Transaction as Txn
import Acadia.UInt64 as UInt64


main : Program Flags Model Msg
main =
    B.application
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        , onUrlRequest = ClickedLink
        , onUrlChange = ChangedUrl
        }



-- MODEL


type alias Model =
    { url : Url
    , key : BN.Key
    , description : String
    , mode : Mode
    , visibility : Visibility
    , entries : List Entry
    }


type Mode
    = Normal
    | Edit EntryId String


type Visibility
    = All
    | Active
    | Completed


type alias Flags =
    ()


init : Flags -> Url -> BN.Key -> ( Model, Cmd Msg )
init _ url key =
    ( Model url key "" Normal (toVisibility url) []
    , Txn.attempt "/_endpoints" GotEntries Backend.getEntries
    )



-- UPDATE


type Msg
    = ClickedLink B.UrlRequest
    | ChangedUrl Url
    | ChangedDescription String
    | SubmittedDescription
    | CheckedEntry EntryId Bool
    | ClickedRemoveButton EntryId
    | CheckedMarkAllCompleted Bool
    | ClickedRemoveCompletedEntriesButton
    | DoubleClickedDescription EntryId String
    | ChangedEntryDescription EntryId String
    | SubmittedEditedDescription
    | FocusedEntry
    | BlurredEntry
    | EscapedEntry
    | GotEntries (Maybe (List Entry))
    | AddedEntry (Maybe Entry)
    | RemovedEntry EntryId (Maybe ())
    | SetCompletedEntry EntryId Bool (Maybe ())
    | SetDescriptionEntry EntryId String (Maybe ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                B.Internal url ->
                    ( model
                    , BN.pushUrl model.key (Url.toString url)
                    )

                B.External href ->
                    ( model
                    , BN.load href
                    )

        ChangedUrl url ->
            ( { model | visibility = toVisibility url }
            , Cmd.none
            )

        ChangedDescription description ->
            ( { model | description = description }
            , Cmd.none
            )

        SubmittedDescription ->
            let
                cleanDescription =
                    String.trim model.description
            in
            if String.isEmpty cleanDescription then
                ( model
                , Cmd.none
                )

            else
                ( { model | description = "" }
                , Txn.attempt "/_endpoints" AddedEntry (Backend.addEntry cleanDescription False)
                )

        CheckedEntry id isChecked ->
            ( model
            , Txn.attempt "/_endpoints" (SetCompletedEntry id isChecked) (Backend.setCompletedEntry id isChecked)
            )

        ClickedRemoveButton id ->
            ( model
            , Txn.attempt "/_endpoints" (RemovedEntry id) (Backend.removeEntry id)
            )

        CheckedMarkAllCompleted isChecked ->
            --
            -- FIXME: It is not currently possible to update an arbitrary number of entries in one transaction.
            --
            --let
            --    updateEntry entry =
            --        { entry | completed = isChecked }
            --in
            --( { model | entries = List.map updateEntry model.entries }
            --, Cmd.none
            --)
            --
            ( model, Cmd.none )

        ClickedRemoveCompletedEntriesButton ->
            --
            -- FIXME: It is not currently possible to update an arbitrary number of entries in one transaction.
            --
            --( { model | entries = List.filter (not << .completed) model.entries }
            --, Cmd.none
            --)
            --
            ( model, Cmd.none )

        DoubleClickedDescription id description ->
            ( { model | mode = Edit id description }
            , focus (entryEditId id) FocusedEntry
            )

        ChangedEntryDescription id description ->
            ( { model | mode = Edit id description }
            , Cmd.none
            )

        SubmittedEditedDescription ->
            case model.mode of
                Normal ->
                    ( model
                    , Cmd.none
                    )

                Edit id description ->
                    let
                        cleanDescription =
                            String.trim description
                    in
                    if String.isEmpty cleanDescription then
                        ( { model | mode = Normal }
                        , Txn.attempt "/_endpoints" (RemovedEntry id) (Backend.removeEntry id)
                        )

                    else
                        let
                            updateEntry entry =
                                if id == entry.id then
                                    { entry | description = cleanDescription }

                                else
                                    entry
                        in
                        ( { model
                            | mode = Normal
                            , entries = List.map updateEntry model.entries
                          }
                        , Txn.attempt "/_endpoints" (SetDescriptionEntry id cleanDescription) (Backend.setDescriptionEntry id cleanDescription)
                        )

        FocusedEntry ->
            ( model
            , Cmd.none
            )

        BlurredEntry ->
            ( { model | mode = Normal }
            , Cmd.none
            )

        EscapedEntry ->
            ( { model | mode = Normal }
            , Cmd.none
            )

        GotEntries maybeEntries ->
            ( case maybeEntries of
                Just entries ->
                    { model | entries = entries }

                Nothing ->
                    model
            , Cmd.none
            )

        AddedEntry maybeEntry ->
            ( case maybeEntry of
                Just entry ->
                    { model | entries = model.entries ++ [ entry ] }

                Nothing ->
                    model
            , Cmd.none
            )

        RemovedEntry id maybeUnit ->
            ( case maybeUnit of
                Just () ->
                    { model
                        | entries = List.filter (\entry -> entry.id /= id) model.entries
                    }

                Nothing ->
                    model
            , Cmd.none
            )

        SetCompletedEntry id isChecked maybeUnit ->
            ( case maybeUnit of
                Just () ->
                    let
                        updateEntry entry =
                            if id == entry.id then
                                { entry | completed = isChecked }

                            else
                                entry
                    in
                    { model | entries = List.map updateEntry model.entries }

                Nothing ->
                    model
            , Cmd.none
            )

        SetDescriptionEntry id cleanDescription maybeUnit ->
            ( case maybeUnit of
                Just () ->
                    let
                        updateEntry entry =
                            if id == entry.id then
                                { entry | description = cleanDescription }

                            else
                                entry
                    in
                    { model | entries = List.map updateEntry model.entries }

                Nothing ->
                    model
            , Cmd.none
            )



-- VIEW


view : Model -> B.Document Msg
view { description, mode, visibility, entries } =
    { title = "Elm Todos"
    , body =
        [ H.section [ HA.class "todoapp" ] <|
            viewPrompt description
                :: viewMain mode visibility entries
        , viewFooter
        ]
    }


viewPrompt : String -> H.Html Msg
viewPrompt description =
    H.header [ HA.class "header" ]
        [ H.h1 [] [ H.text "todos" ]
        , H.form [ HE.onSubmit SubmittedDescription ]
            [ H.input
                [ HA.type_ "text"
                , HA.autofocus True
                , HA.placeholder "What needs to be done?"
                , HA.class "new-todo"
                , HA.value description
                , HE.onInput ChangedDescription
                ]
                []
            ]
        ]


viewMain : Mode -> Visibility -> List Entry -> List (H.Html Msg)
viewMain mode visibility entries =
    if List.isEmpty entries then
        []

    else
        [ H.section [ HA.class "main" ]
            [ H.input
                [ HA.type_ "checkbox"
                , HA.id "toggle-all"
                , HA.class "toggle-all"
                , HA.checked (List.all .completed entries)
                , HE.onCheck CheckedMarkAllCompleted
                ]
                []
            , H.label [ HA.for "toggle-all" ] [ H.text "Mark all as completed" ]
            , H.ul [ HA.class "todo-list" ] <|
                List.map
                    (\entry ->
                        H.li
                            [ HA.classList
                                [ ( "completed", entry.completed )
                                , ( "editing", isEditing mode entry )
                                ]
                            ]
                            [ viewEntry mode entry ]
                    )
                    (keep visibility entries)
            ]
        , H.footer [ HA.class "footer" ] <|
            List.concat
                [ [ viewStatus entries
                  , viewVisibilityFilters visibility
                  ]
                , viewClearCompleted entries
                ]
        ]


viewEntry : Mode -> Entry -> H.Html Msg
viewEntry mode entry =
    case mode of
        Normal ->
            viewEntryNormal entry

        Edit id description ->
            if id == entry.id then
                viewEntryEdit id description

            else
                viewEntryNormal entry


viewEntryNormal : Entry -> H.Html Msg
viewEntryNormal { id, description, completed } =
    H.div [ HA.class "view" ]
        [ H.input
            [ HA.type_ "checkbox"
            , HA.checked completed
            , HA.class "toggle"
            , HE.onCheck (CheckedEntry id)
            ]
            []
        , H.label [ HE.onDoubleClick (DoubleClickedDescription id description) ]
            [ H.text description ]
        , H.button
            [ HA.type_ "button"
            , HA.class "destroy"
            , HE.onClick (ClickedRemoveButton id)
            ]
            []
        ]


viewEntryEdit : EntryId -> String -> H.Html Msg
viewEntryEdit id description =
    H.form [ HE.onSubmit SubmittedEditedDescription ]
        [ H.input
            [ HA.type_ "text"
            , HA.id (entryEditId id)
            , HA.value description
            , HA.class "edit"
            , HE.onInput (ChangedEntryDescription id)
            , HE.onBlur BlurredEntry
            , onEsc EscapedEntry
            ]
            []
        ]


viewStatus : List Entry -> H.Html msg
viewStatus entries =
    let
        n =
            entries
                |> List.filter (not << .completed)
                |> List.length
    in
    H.span [ HA.class "todo-count" ]
        [ H.strong [] [ H.text (String.fromInt n) ]
        , H.text <| " " ++ pluralize n "item" "items" ++ " left"
        ]


viewVisibilityFilters : Visibility -> H.Html msg
viewVisibilityFilters selected =
    H.ul [ HA.class "filters" ]
        [ H.li [] [ viewVisibilityFilter "All" "#/" All selected ]
        , H.li [] [ viewVisibilityFilter "Active" "#/active" Active selected ]
        , H.li [] [ viewVisibilityFilter "Completed" "#/completed" Completed selected ]
        ]


viewVisibilityFilter : String -> String -> Visibility -> Visibility -> H.Html msg
viewVisibilityFilter name url current selected =
    H.a
        [ HA.href url
        , HA.classList [ ( "selected", current == selected ) ]
        ]
        [ H.text name ]


viewClearCompleted : List Entry -> List (H.Html Msg)
viewClearCompleted entries =
    let
        completedEntries =
            List.filter .completed entries

        numCompletedEntries =
            List.length completedEntries
    in
    if numCompletedEntries == 0 then
        []

    else
        [ H.button
            [ HA.type_ "button"
            , HA.class "clear-completed"
            , HE.onClick ClickedRemoveCompletedEntriesButton
            ]
            [ H.text <| "Clear completed (" ++ String.fromInt numCompletedEntries ++ ")" ]
        ]


viewFooter : H.Html msg
viewFooter =
    H.footer [ HA.class "info" ]
        [ H.p [] [ H.text "Double-click to edit a todo" ]
        , H.p []
            [ H.text "Written by "
            , H.a [ HA.href "https://github.com/dwayne" ] [ H.text "Dwayne Crooks" ]
            ]
        ]



-- HELPERS


toVisibility : Url -> Visibility
toVisibility url =
    case ( url.path, url.fragment ) of
        ( "/", Just "/active" ) ->
            Active

        ( "/", Just "/completed" ) ->
            Completed

        _ ->
            All


entryEditId : EntryId -> String
entryEditId (EntryId id) =
    "entry-edit-" ++ UInt64.toString id


isEditing : Mode -> Entry -> Bool
isEditing mode entry =
    case mode of
        Normal ->
            False

        Edit id _ ->
            id == entry.id


keep : Visibility -> List Entry -> List Entry
keep visibility entries =
    case visibility of
        All ->
            entries

        Active ->
            List.filter (not << .completed) entries

        Completed ->
            List.filter .completed entries


pluralize : Int -> String -> String -> String
pluralize n singular plural =
    if n == 1 then
        singular

    else
        plural


focus : String -> msg -> Cmd msg
focus id msg =
    BD.focus id
        |> Task.attempt (always msg)


onEsc : msg -> H.Attribute msg
onEsc msg =
    let
        decoder =
            HE.keyCode
                |> JD.andThen
                    (\n ->
                        case n of
                            27 ->
                                JD.succeed msg

                            _ ->
                                JD.fail "ignored"
                    )
    in
    HE.on "keydown" decoder

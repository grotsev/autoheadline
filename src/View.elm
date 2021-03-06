module View exposing (..)

import Dict
import Document
import Exts.Http exposing (cgiParameters)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Markov
import Set
import String
import Types exposing (..)


rootView : Model -> Html Msg
rootView model =
    div [ class "container" ]
        [ div [ class "row" ]
            [ div [ class "col-xs-12" ]
                [ body model ]
            ]
        ]


itemView : NewsItem -> Html msg
itemView item =
    div [ class "real-headline" ]
        [ text item.title ]


tokenButton : ( String, Int ) -> Html Msg
tokenButton ( token, linkCount ) =
    let
        buttonType =
            if linkCount <= 1 then
                "btn-default"
            else if linkCount <= 3 then
                "btn-info"
            else if linkCount <= 6 then
                "btn-warning"
            else
                "btn-danger"
    in
        button
            [ classList
                [ ( "token", True )
                , ( "btn", True )
                , ( buttonType, True )
                ]
            , onClick (ChooseToken token)
            ]
            [ text token
            , text " "
            ]


tokenButtons : List ( String, Int ) -> Html Msg
tokenButtons weightedTokens =
    div []
        (List.map (tokenButton)
            weightedTokens
        )


showWord : String -> String
showWord word =
    if word == Markov.startToken then
        ""
    else if word == Markov.endToken then
        ""
    else
        word


body : Model -> Html Msg
body model =
    div []
        [ div [ class "row" ]
            [ div [ class "col-xs-12 col-sm-8 col-sm-offset-2" ]
                [ h2 []
                    [ text "Make Your Own HackerNews Headline" ]
                , h3 []
                    [ text " from the latest 200 stories." ]
                ]
            , div [ class "col-xs-12 col-sm-2" ]
                [ h4 []
                    [ a [ href "https://github.com/krisajenkins/autoheadline" ]
                        [ text "See the source code" ]
                    ]
                ]
            ]
        , div [ class "row" ]
            [ div [ class "col-xs-12 col-sm-8 col-sm-offset-2" ]
                [ div [ class "well" ]
                    [ h1 [] [ text <| formattedPhrase model.phrase ] ]
                ]
            ]
        , case model.newsItems of
            Just (Ok items) ->
                newsBody model.phrase items

            Just (Err err) ->
                div [ class "alert alert-danger" ]
                    [ text (toString err) ]

            _ ->
                loading
        ]


formattedPhrase : List String -> String
formattedPhrase =
    List.map showWord
        >> String.join " "
        >> String.trim


newsBody : List String -> List NewsItem -> Html Msg
newsBody currentPhrase newsItems =
    let
        currentToken =
            Maybe.withDefault Markov.startToken
                (List.head (List.reverse currentPhrase))

        graph =
            graphFromNews newsItems

        nextTokens =
            Dict.get currentToken graph

        weighToken token =
            ( token
            , List.length ((Set.toList (Maybe.withDefault Set.empty (Dict.get token graph))))
            )
    in
        div []
            [ div [ class "row" ]
                [ div [ class "col-xs-12 col-sm-2 well" ]
                    [ text "Click any button to choose the next word." ]
                , div [ class "col-xs-12 col-sm-8" ]
                    [ case nextTokens of
                        Nothing ->
                            div [ class "btn-group" ]
                                [ button
                                    [ class "btn btn-warning reset"
                                    , onClick Reset
                                    ]
                                    [ text "Reset" ]
                                , a
                                    [ class "btn btn-success"
                                    , target "_blank"
                                    , href <| shareLink <| formattedPhrase currentPhrase
                                    ]
                                    [ text "Tweet This" ]
                                ]

                        Just tokens ->
                            let
                                weightedTokens =
                                    List.map weighToken (Set.toList tokens)
                            in
                                tokenButtons weightedTokens
                    ]
                ]
            , div [ class "row" ]
                [ div [ class "col-xs-12 col-sm-8 col-sm-offset-2" ]
                    [ div [] (List.map itemView newsItems) ]
                ]
            ]


loading : Html msg
loading =
    div [ class "loading" ]
        [ img
            [ src "loading_wheel.gif"
            , class "loading"
            ]
            []
        ]


shareLink : String -> String
shareLink body =
    "https://twitter.com/intent/tweet?"
        ++ (cgiParameters
                [ ( "url", Document.locationHref () )
                , ( "via", "krisajenkins" )
                , ( "text", "\"" ++ body ++ "\"\n\n" )
                ]
           )

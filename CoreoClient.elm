module CoreoClient exposing (..)
{-| This is the top-level Elm module for a web client interface created for
Brazilian dancer André Aguiar's multimedia choreography <name here>.

For usage details, check main.js.

@docs main 
-}

import CoreoClient.VoteList as VoteList
import CoreoClient.NewWordList as NewWordList

import Html as H exposing (Html)
import Html.App as App

--url for the words API
wordsUrl : String
wordsUrl = "http://localhost:4000/api/v1/words/"

newWordsUrl : String
newWordsUrl = "http://localhost:4000/api/v1/new_words/"

socketUrl : String
socketUrl = "ws://localhost:4000/socket/websocket"

{-| main: Start the client.
-}
main : Program Never
main = 
    App.program 
         { init = init
         , view = view
         , update = update
         , subscriptions = subscriptions
         }
      
type alias Model =
    { voteList : VoteList.Model
    , newWordList : NewWordList.Model
    }


type Msg 
    = VoteMsg VoteList.Msg
    | NewWordMsg NewWordList.Msg

init : (Model, Cmd Msg)
init = 
  let (newVoteList, voteListCmd) = VoteList.init wordsUrl socketUrl

      (newWordList, wordListCmd) = NewWordList.init newWordsUrl

  in ( { voteList = newVoteList
       , newWordList = newWordList
       }
     , Cmd.batch
         [ Cmd.map VoteMsg voteListCmd
         , Cmd.map NewWordMsg wordListCmd
         ]
     )


update : Msg -> Model -> (Model, Cmd Msg)
update message model = 
  case message of
    VoteMsg msg ->
      let (newVoteList, voteListCmd) = VoteList.update msg model.voteList
      in ({ model | voteList = newVoteList }, Cmd.map VoteMsg voteListCmd)

    NewWordMsg msg ->
      let (newWordList, wordListCmd) = NewWordList.update msg model.newWordList
      in ({ model | newWordList = newWordList }, Cmd.map NewWordMsg wordListCmd)


view : Model -> Html Msg
view model = 
    H.div []
         [ App.map VoteMsg <| VoteList.view model.voteList
         , App.map NewWordMsg <| NewWordList.view model.newWordList
         ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
         [ Sub.map VoteMsg <| VoteList.subscriptions model.voteList
         , Sub.map NewWordMsg <| NewWordList.subscriptions model.newWordList
         ]

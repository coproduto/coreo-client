module CoreoClient.VoteList exposing (Model, Msg, update, view, init, subscriptions)
{-| Module to generate a list of votes,
consisting of each votable option together
with the number of votes associated with it.

@docs Model

@docs Msg

@docs update

@docs view 

@docs init
-}

import Html as H exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events

import Http
import Task exposing (Task)

import Result exposing (Result)
import Json.Decode as Decode exposing (Decoder,(:=))

import Debug

{-| Underlying data for a VoteList-}
type alias Model = 
  { votes : List Votes
  , votedForOption : Maybe Int
  , url : String
  }

{-| Type for messages generated from a voteList.
A message generated by the list always contains a
string identifying which option was voted for. 
-}
type Msg = VoteForOption Int
         | UpdateListFail Http.Error
         | UpdateListSucceed (List Votes)
         | IncrementFail Http.Error
         | IncrementSucceed Votes
         | DecrementFail Http.Error
         | DecrementSucceed Votes

type alias Votes =
  { id : Int
  , name: String
  , votes: Int 
  }

{-| Initialize the voteList. It takes a list of strings representing
the possible voting options as a parameter. 
-}
init : String -> (Model, Cmd Msg)
init url = 
  ( Model 
      []
      Nothing 
      url
  , Task.perform UpdateListFail UpdateListSucceed (Http.get decodeVoteList url)
  )

{-| Step the vote list whenever we get a new vote 
-}
update : Msg -> Model -> (Model, Cmd Msg)
update message model =
  case message of
    VoteForOption id ->
      case model.votedForOption of
        Just voted ->
          if voted == id then
            ( model
            , Task.perform DecrementFail DecrementSucceed 
               (Http.post decodeVoteResponse 
                  (model.url++"decrement/"++(toString id)) Http.empty)
            )
          else
            (model, Cmd.none)

        Nothing ->
          ( model 
          , Task.perform IncrementFail IncrementSucceed
              (Http.post decodeVoteResponse 
                 (model.url++"increment/"++(toString id)) Http.empty)
          )

    UpdateListFail err ->
      (Debug.log ("got err " ++ (toString err)) model
      , Cmd.none
      )

    UpdateListSucceed vList ->
      (Debug.log ("got vList " ++ (toString vList))
       { model | votes = vList
       }
       , Cmd.none
      )

    IncrementFail err ->
      (Debug.log ("got err " ++ (toString err)) model
      , Cmd.none
      )

    IncrementSucceed vote ->
      (Debug.log ("got vote " ++ (toString vote))
         { model | votes = dispatchAction increment vote.id model.votes 
         , votedForOption = Just vote.id
         }
       , Cmd.none
      )

    DecrementFail err ->
      (Debug.log ("got err " ++ (toString err)) model
      , Cmd.none
      )

    DecrementSucceed vote ->
      (Debug.log ("got vote " ++ (toString vote))
         { model | votes = dispatchAction decrement vote.id model.votes 
         , votedForOption = Nothing
         }
       , Cmd.none
      )


{-| The voteList gets shown as an HTML `ul` element with
the name of the option, the number of votes, and a voting
button. -} 
view : Model -> Html Msg
view model = 
  H.div []
     [ voteList (List.sortBy (\a -> negate a.votes) model.votes) ]

subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none
      
--helper functions
voteList : List Votes -> Html Msg
voteList vList =
  let list =
    List.map listElem vList
  in H.ul [] list

listElem : Votes -> Html Msg
listElem vote =
  H.li []
     [ H.text (vote.name ++ ":" ++ (toString vote.votes))
     , H.button
         [ Events.onClick (VoteForOption vote.id) ]
         [ H.text "Vote" ] 
     ]

dispatchAction : (Int -> Int) -> Int -> List Votes -> List Votes
dispatchAction action target list =
  case list of
    (vote :: rest) ->
      if vote.id == target then { vote | votes = action (vote.votes) } :: rest
      else vote :: (dispatchAction action target rest)

    [] -> []

increment x = x + 1

decrement x = x - 1
--

--decoders for JSON data

decodeVoteList : Decoder (List Votes)
decodeVoteList = 
  let vList = decodeVote |> Decode.list
  in ("data" := vList)

decodeVote : Decoder Votes
decodeVote =
 Decode.object3 Votes 
   ("id"    := Decode.int)
   ("name"  := Decode.string) 
   ("votes" := Decode.int) 
         
decodeVoteResponse : Decoder Votes
decodeVoteResponse =
  ("data" := decodeVote)

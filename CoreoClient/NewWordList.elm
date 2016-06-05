module CoreoClient.NewWordList exposing (Model, Msg, update, view, init)
{-| Module allowing users to vote for a new word to be added 
to the voting list. Functions quite similarly to the voting
list itself.

@docs Model

@docs Msg

@docs update

@docs view

@docs init 
-} 

import Html as H exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events

{-| Underlying data for the NewWordList, containing a list of (String, Int, Bool) type
-} 
type alias Model = 
  { votes : List (String, Int, Bool) 
  , fieldContent : String 
  }

{-| Type for messages generated from a voteList.
A message can either represent a vote for a given option
or it can represent the creation of a new option.
-}
type Msg 
  = VoteForOption String
  | CreateOption String
  | NewContent String

{-| The newWordList is always initialized as empty.
-}
init : (Model, Cmd Msg)
init = 
  (Model [] "", Cmd.none)

{-| We step the list whenever we get a new vote or a new option is created.
-}
update : Msg -> Model -> (Model, Cmd Msg)
update message model =
  case message of
    VoteForOption str ->
      ({ model | votes = dispatch3 toggleAndModify str model.votes }, Cmd.none)

    CreateOption str ->
      let options = List.map fst3 model.votes
      in if str `List.member` options then
           (model,Cmd.none)
         else 
           ({ model | votes = (str, 1, True) :: model.votes 
                    , fieldContent = ""
            }, Cmd.none)

    NewContent str ->
      ({ model | fieldContent = str }, Cmd.none)

{-| Show the NewWordList -}
view : Model -> Html Msg
view model =
  H.div []
   [ voteList model.votes 
   , H.input 
       [ Attr.placeholder "Crie uma opção"
       , Events.onInput NewContent
       , Attr.value model.fieldContent
       ] []
   , H.button 
      [ Events.onClick (CreateOption model.fieldContent) ]
      [ H.text "Confirmar opção" ]
   ]

--helper functions
fst3 : (a,b,c) -> a
fst3 (x,_,_) = x

dispatch3 : ((b,c) -> (b,c)) -> a -> List (a,b,c) -> List (a,b,c)
dispatch3 action target list =
  case list of
    ((a,b,c) :: rest) ->
      if a == target then 
        let (x,y) = action (b,c)
        in (a,x,y) :: rest

      else (a,b,c) :: (dispatch3 action target rest)

    [] -> []

toggleAndModify : (Int,Bool) -> (Int,Bool)
toggleAndModify (n, b) =
  if b then (n+1, not b)
  else (n-1, not b)

voteList : List (String, Int, Bool) -> Html Msg
voteList tripleList =
  H.ul [] (List.map listElem tripleList)

listElem : (String, Int, Bool) -> Html Msg
listElem (str, n, b) =
  let voteText = if b then "+1"
                 else "0"
  in 
    H.li []
       [ H.text (str ++ ":" ++ voteText)
       , H.button
          [ Events.onClick (VoteForOption str) ]
          [ H.text "Vote" ]
       ]


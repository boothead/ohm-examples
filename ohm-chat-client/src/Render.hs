{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}
module Render (
    rootView
  ) where

import Control.Lens hiding (children)
import Data.Maybe (fromMaybe)
import Data.Monoid ((<>))
import qualified Data.Set as S
import Data.Set (Set)
import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.Text.Lens as Lens
import Ohm.HTML
import Messages
import Prelude hiding (div,id,span,map)
import qualified Prelude as P
import ChatTypes
           
chatStatsRender :: Set Text -> HTML
chatStatsRender chatters =
  row
    [ col3 [into strong [text $ (Text.pack . show $ S.size chatters) <> " people chatting"]]
    , col6 $ nameListRender chatters
    ]

typingRender :: Set Text -> HTML
typingRender typers =
  row
    [ col3 [into strong ["Currently typing:"]]
    , col6 $ nameListRender typers
    ]
    
nameListRender :: Set Text -> [HTML]
nameListRender names = P.map mkName $ S.toAscList names
  where mkName n = with span (classes .= ["label", "label-default"]) [text n]
      
msgRender :: Said -> HTML
msgRender (Said nm msg) =
  row
    [ col3 [into strong [text $ nm <> " said: "]]
    , col3 [into p $ [text msg]]
    ]


textBoxRender :: Maybe Text -> Text -> DOMEvent ChatMessage -> HTML
textBoxRender name value saidEvent@(DOMEvent chan) =
  with form (classes .= ["form-inline row"])
    [ with div (classes .= ["form-group col-sm-3"])
        [ with label (classes .= ["form-control-static"])
            [ "Say something"]
        ]
    , with div (classes .= ["form-group col-sm-6"]) 
        [ with input (do
            classes .= ["form-control"]
            attrs . at "placeholder" ?= "Enter Message"
            attrs . at "value" ?= (toJSString value)
            onInput $ contramap (EnteringText . Text.pack)saidEvent)
            []
        ]
      , mkButton sendMessage "Send Message" ["btn-primary"]
    ]
  where addName said = EnterMessage $ Said (fromMaybe "Unknown" name) said
        sendMessage = const $ chan (addName value)

chatRender :: DOMEvent ChatMessage -> ChatModel -> HTML
chatRender chan (ChatModel msgs chatters typers name currentMsg) =
  container
   ( [chatStatsRender chatters]
  ++ P.map msgRender msgs
  ++ [typingRender typers]
  ++ [textBoxRender name currentMsg chan]
   )
  
loginRender :: DOMEvent LoginMessage -> LoginModel -> HTML
loginRender chan m = 
  with form (classes .= ["form-inline row"])
    [ with div (classes .= ["form-group col-sm-3"])
        [ with label (classes .= ["form-control-static"])
            [ "What's your name?"]
        ]
    , with div (classes .= ["form-group col-sm-6"]) 
        [ with input (do
            classes .= ["form-control"]
            attrs . at "placeholder" ?= "Enter Name"
            attrs . at "value" ?= (m ^. loginBox.Lens.unpacked.to toJSString)
            onInput $ contramap (EnteringName . Text.pack) chan)
            []
        ]
      , mkButton (const . channel chan $ (UserLogin (m ^. loginBox))) "Login" ["btn-primary"]
    ]

rootView :: DOMEvent Message -> AppModel -> HTML
rootView chan m =
  container
    [ with nav (classes .= ["nav", "navbar", "navbar-default"])
       [with div (classes .= ["navbar-brand"])
         ["Demo"]]
                  
       , case (m ^. currentView) of
           LoginView -> embedRenderer loginRender _Login login chan m             
           ChatView ->  embedRenderer chatRender _Chat chat chan m
         
    ]

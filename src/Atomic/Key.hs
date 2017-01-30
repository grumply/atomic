module Atomic.Key where

import Data.Txt

import Atomic.FromTxt
import Atomic.ToTxt

import Data.Hashable
import Data.String
import Data.Monoid

newtype Key phantom = Key { getKey :: (Txt,Int) }
  deriving (Show)

instance FromTxt (Key phantom) where
  fromTxt t = Key (t,hash t)

instance ToTxt (Key phantom) where
  toTxt = fst . getKey

instance IsString (Key a) where
  fromString str =
    let h = hash str
    in h `seq` Key (fromString str,h)

instance Monoid (Key phantom) where
  mempty = Key (fromString "",hash "")
  mappend (Key (jss0,_)) (Key (jss1,_)) =
    let h = hash (fromTxt jss0 ++ fromTxt jss1 :: String)
    in Key (jss0 <> jss1,h)

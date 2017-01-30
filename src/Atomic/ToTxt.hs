{-# language OverloadedStrings #-}
{-# language CPP #-}
module Atomic.ToTxt where

import Atomic.ToBS

import Numeric

import Data.Txt
import Data.JSON

#ifdef __GHCJS__
import Data.JSString.RealFloat
import Data.JSString.Int
import GHCJS.Types
import GHCJS.Marshal.Pure
import GHCJS.Marshal
import System.IO.Unsafe
#endif

import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BSL
import qualified Data.ByteString.Lazy.Char8 as BSLC
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TL
import qualified Data.Text.Lazy.Builder as Builder
import qualified Data.Text.Lazy.Builder.Int as Builder

-- ToTxt is representational and is thus uni-directional. For a fully
-- bidirectional encoding, see ToBS/FromBS where the expectation is that
-- fromBS (toBS a) = Right and fmap toBS . fromBS = Right
--
-- ToTxt is used to construct, possibly unique, resource identifiers.
--
-- Note the default instance uses a ToBS instance to construct a text value
-- from a full encoding of the term; this is slow since ToBS generates a
-- lazy bytestring and we must use lazy decoding and subsequent strictness
-- conversion. For small terms, which is the intended use-case for the
-- default instance, this won't matter much.
class ToTxt a where
  toTxt :: a -> Txt
  default toTxt :: ToBS a => a -> Txt
#ifdef __GHCJS__
  toTxt = pack . BSLC.unpack . toBS
#else
  toTxt = TL.toStrict . TL.decodeUtf8 . toBS
#endif

instance ToTxt Value where
#ifdef __GHCJS__
  toTxt = encode
#else
  toTxt = toTxt . encode
#endif

instance ToTxt () where
  toTxt _ = "()"

instance ToTxt BSL.ByteString where
  -- can this fail at runtime from a bad encoding?
  toTxt = toTxt . TL.decodeUtf8

instance ToTxt B.ByteString where
  -- can this fail at runtime from a bad encoding?
  toTxt = toTxt . T.decodeUtf8

instance ToTxt Txt where
  toTxt = id

#ifdef __GHCJS__
instance ToTxt T.Text where
  toTxt = textToJSString
#endif

instance ToTxt TL.Text where
#ifdef __GHCJS__
  toTxt = lazyTextToJSString
#else
  toTxt = TL.toStrict
#endif

instance ToTxt Char where
#ifdef __GHCJS__
  toTxt = singleton
#else
  toTxt = T.singleton
#endif

instance ToTxt String where
#ifdef __GHCJS__
  toTxt = pack
#else
  toTxt = T.pack
#endif

instance ToTxt Int where
#ifdef __GHCJS__
  toTxt = decimal
#else
  toTxt = shortText . Builder.decimal
#endif

instance ToTxt Integer where
#ifdef __GHCJS__
  toTxt = decimal
#else
  toTxt = shortText . Builder.decimal
#endif

instance ToTxt Float where
#ifdef __GHCJS__
  toTxt = realFloat
#else
  toTxt = toTxt . ($ "") . showFFloat Nothing
#endif

instance ToTxt Double where
#ifdef __GHCJS__
  toTxt = realFloat
#else
  toTxt = toTxt . ($ "") . showFFloat Nothing
#endif



instance ToTxt Bool where
  toTxt True  = "true"
  toTxt False = "false"

shortText :: Builder.Builder -> T.Text
shortText = TL.toStrict . Builder.toLazyTextWith 32

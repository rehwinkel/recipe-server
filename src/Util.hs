{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE NoFieldSelectors #-}

module Util (Occurence (None, One, Many), occurences, maybeOccurs, getTimeSinceEpoch, extractCookie) where

import Data.Int (Int64)
import Data.List qualified
import Data.Text (Text)
import Data.Text qualified
import Data.UnixTime
import Foreign.C (CTime (CTime))

data Occurence a = None | One a | Many

occurences :: [a] -> Occurence a
occurences [] = None
occurences [a] = One a
occurences _ = Many

maybeOccurs :: Occurence a -> Maybe a
maybeOccurs None = Nothing
maybeOccurs Many = Nothing
maybeOccurs (One v) = Just v

data Cookie = Cookie {name :: Text, cookieValue :: Text} deriving (Show)

makeCookieFromList :: [Text] -> Cookie
makeCookieFromList [a, b] = Cookie a b
makeCookieFromList _ = error "Failure constructing cookie from key-value-pair"

extractCookie :: Text -> Text -> Maybe Text
extractCookie cookieName cookies = do
  let cookieList = makeCookieFromList . Data.Text.splitOn "=" . Data.Text.strip <$> Data.Text.splitOn ";" cookies
   in (.cookieValue) <$> Data.List.find (\cookie -> cookie.name == cookieName) cookieList

getTimeSinceEpoch :: IO Int64
getTimeSinceEpoch = do
  epochTime <- toEpochTime <$> getUnixTime
  case epochTime of
    CTime time -> return time

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (when)
import Data.Aeson (decode)
import Data.Aeson.Types
import Data.ByteString.Lazy qualified as B
import Data.Maybe
import Data.Text hiding (map)
import Database.SQLite.Simple
import GHC.Generics (Generic)
import Ingredients (createIngredientsTables, handleAddRecipeIngredient, handleCreateIngredient, handleGetIngredient, handleGetIngredients, handleGetRecipeIngredients)
import Recipe (createRecipeTable, handleAddRecipe, handleDeleteRecipe, handleGetAllRecipes, handleGetRecipe)
import User (createUser, handleLogin, handleRegister)
import Web.Scotty (delete, get, post, scotty)
import Images (createImageTable, handleGetImage, storeImageInDB, handleGetAssociatedImageUUIDs)
import Codec.Picture (generateImage, PixelRGB8 (PixelRGB8), DynamicImage (ImageRGB8))
import Control.Monad.IO.Class (MonadIO(liftIO))

createTables :: Connection -> IO ()
createTables db = do
  execute_ db "CREATE TABLE IF NOT EXISTS sessions (token VARCHAR(40) PRIMARY KEY, userId INTEGER NOT NULL, timestamp INTEGER NOT NULL);"
  execute_ db "CREATE TABLE IF NOT EXISTS users (userId INTEGER PRIMARY KEY AUTOINCREMENT, username VARCHAR(255) NOT NULL, passwordHash VARCHAR(80) NOT NULL);"
  createIngredientsTables db
  createRecipeTable db
  createImageTable db

data ServerConfig = ServerConfig {port :: Int, adminPassword :: Text} deriving (Generic)

instance FromJSON ServerConfig

main :: IO ()
main = do
  configBytes <- B.readFile "config.json"
  let config = fromMaybe ServerConfig {port = 3000, adminPassword = "admin"} (decode configBytes)
  db <- open "recipes.sqlite"
  createTables db
  adminSuccess <- createUser db "admin" (adminPassword config)
  when adminSuccess $ putStrLn "Created user \"admin\""
  -- _ <- liftIO $ storeImageInDB db "some_image" (ImageRGB8 $ generateImage (curry $ const (PixelRGB8 10 10 10)) 100 100) 1
  scotty (port config) $ do
    post "/register" $ handleRegister db
    post "/login" $ handleLogin db
    get "/ingredients" $ handleGetIngredients db
    post "/ingredients" $ handleCreateIngredient db
    get "/ingredients/:ingredientId" $ handleGetIngredient db
    get "/recipes" $ handleGetAllRecipes db
    get "/recipes/:recipeId" $ handleGetRecipe db
    delete "/recipes/:recipeId" $ handleDeleteRecipe db
    post "/recipes" $ handleAddRecipe db
    get "/recipes/:recipeId/ingredients" $ handleGetRecipeIngredients db
    post "/recipes/:recipeId/ingredients" $ handleAddRecipeIngredient db
    get "/recipes/:recipeId/images" $ handleGetAssociatedImageUUIDs db
    get "/images/:uuid" $ handleGetImage db
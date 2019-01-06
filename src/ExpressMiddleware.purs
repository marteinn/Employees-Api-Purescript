module ExpressMiddleware where

import Prelude
import Data.Function.Uncurried (Fn3)
import Node.Express.Types (Response, Request)
import Effect (Effect)

foreign import jsonBodyParser :: Fn3 Request Response (Effect Unit) (Effect Unit)

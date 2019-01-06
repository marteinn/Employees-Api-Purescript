module Dynamo where


import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Effect (Effect)
import Effect.Aff (Aff)
import Data.Either (Either)
import Prelude
import Debug.Trace (traceM)


{--import Control.Monad.Eff (Eff)--}

{--foreign import data AAA :: *--}
{--foreign import createTable :: String -> (True -> Eff (fs :: FS | eff) Unit)--}

{--createTable:: forall eff. (AAA -> Eff (geolookup :: GeoLookup | eff) Unit) ->--}
                           {--Eff (geolookup :: GeoLookup | eff) Unit--}

{--foreign import data TrueObj :: !--}
{--type TrueObj :: Bool--}
{--foreign import data TrueObj :: Type--}
{--foreign import data DYNAMO :: Type--}
{--foreign import data Response :: Type--}
{--foreign import data Param :: Type--}
{--foreign import data GeoLookup :: Type--}
{--foreign import data Request :: Type--}
{--foreign import data AJAX :: Type--}
{--foreign import data Position :: # Type--}

{--import Data.Foreign (Foreign, writeObject)--}

foreign import setConfigurationImpl :: forall r. AWSConfig -> r

type AWSConfig = { endpoint :: String
                 , accessKeyId :: String
                 , secretAccessKey :: String
                 , region :: String
                 , apiVersion :: String
                 }

setConfiguration :: forall r. AWSConfig -> r
setConfiguration conf = setConfigurationImpl conf


foreign import createTableImpl :: forall a b. a -> EffectFnAff b

createTable :: forall a b. a -> Aff b
createTable = fromEffectFnAff <<< createTableImpl


foreign import putDocImpl :: forall a b c. a -> b -> EffectFnAff c

putDoc :: forall a b c. a -> b -> Aff c
putDoc a b = fromEffectFnAff (putDocImpl a b)


foreign import scanDocImpl :: forall a b c. a -> b -> EffectFnAff c

scanDoc :: forall a b c. a -> b -> Aff c
scanDoc a b = fromEffectFnAff (scanDocImpl a b)


foreign import deleteDocImpl :: forall a b c. a -> b -> EffectFnAff c

deleteDoc :: forall a b c. a -> b -> Aff c
deleteDoc a b = fromEffectFnAff (deleteDocImpl a b)


foreign import queryDocImpl :: forall a b c. a -> b -> EffectFnAff c

queryDoc :: forall a b c. a -> b -> Aff c
queryDoc a b = fromEffectFnAff (queryDocImpl a b)

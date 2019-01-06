module Dynamo where

import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)
import Effect (Effect)
import Effect.Aff (Aff)
import Data.Either (Either)
import Prelude
import Debug.Trace (traceM)

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

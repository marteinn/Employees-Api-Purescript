module Main where

import Prelude hiding (apply)
import Data.Maybe (Maybe(..))
import Data.Either (Either(..))
import Data.Array (head)
import Effect (Effect)
import Effect.Console (log)
import Effect.Aff (Aff, attempt)
import Effect.Aff.Class (liftAff)
import Effect.Exception (error)
import Node.Express.App (App, listenHttp, useExternal, get, post, put, delete)
import Node.Express.Response (sendJson, setStatus)
import Node.Express.Handler (Handler, nextThrow)
import Node.Express.Request (getBodyParam, getRouteParam)
import Node.HTTP (Server)
import Dynamo (setConfiguration, createTable, putDoc, scanDoc, deleteDoc,
			   queryDoc)
{--import Debug.Trace (traceM)--}
import ExpressMiddleware (jsonBodyParser)


--Helpers

scanEmployee :: forall a b. a -> Aff b
scanEmployee = scanDoc { "TableName": "employees" }

putEmployee :: forall a b. a -> Aff b
putEmployee = putDoc { "TableName": "employees" }

queryEmployee :: forall a b. a -> Aff b
queryEmployee = queryDoc { "TableName": "employees" }

queryEmployeeByEmail :: forall a b. a -> Aff b
queryEmployeeByEmail email = queryEmployee 
    { "KeyConditionExpression": "email = :email"
    , "ExpressionAttributeValues": 
        {
        ":email": email
        }
    }

deleteEmployee :: forall a b. a -> Aff b
deleteEmployee = deleteDoc { "TableName": "employees" }


--Handlers

indexHandler :: Handler
indexHandler = do
    resp <- liftAff $ attempt $ scanEmployee {}
    case resp of
        Right employees -> sendJson $ employees
        Left err -> nextThrow $ err

createHandler :: Handler
createHandler = do
    emailParam <- getBodyParam "email"
    companyParam <- getBodyParam "company"

    case [emailParam, companyParam] of
         [Just email, Just company] -> do
            let model = { "email": email, "company": company }
            resp <- liftAff $ attempt $ putEmployee model
            case resp of
                Right _ -> sendJson $ model
                Left err -> nextThrow $ err
         _ -> nextThrow $ error $ "Missing values"

deleteHandler :: Handler
deleteHandler = do
    emailParam <- getRouteParam "email"
    case emailParam of
        Just email -> do
            employeesResp <- liftAff $ attempt $ queryEmployeeByEmail email
            case employeesResp of
                Right employees -> do
                    case head $ employees of
                         Just employee -> do
                            let model = { email: employee.email
                                        , company: employee.company
                                        }
                            resp <- liftAff $ attempt $ deleteEmployee model
                            sendJson $ {}
                         _ -> nextThrow $ error $ "Employee list is empty"
                Left err -> nextThrow $ err

        _ -> do
            setStatus 404
            sendJson {}

detailHandler :: Handler
detailHandler = do
    emailParam <- getRouteParam "email"
    case emailParam of
        Just email -> do
            employeesResp <- liftAff $ attempt $ queryEmployeeByEmail email
            case employeesResp of
                Right employees -> do
                    case head $ employees of
                        Just employee -> sendJson $ employee
                        _ -> nextThrow $ error "User not found"
                Left err -> nextThrow $ err
        _ -> nextThrow $ error "Missing email param"

createLocalDbHandler :: Handler
createLocalDbHandler = do
    let table = { "TableName": "employees"
                , "KeySchema": 
                    [ { "AttributeName": "email", "KeyType": "HASH" }
                    , { "AttributeName": "company", "KeyType": "RANGE" }
                    ]
                , "AttributeDefinitions":
                    [ { "AttributeName": "email", "AttributeType": "S" }
                    , { "AttributeName": "company", "AttributeType": "S" }
                    ]
                , "ProvisionedThroughput":
                    { "ReadCapacityUnits": 5
                    , "WriteCapacityUnits": 5
                    }
                }

    resp <- liftAff $ attempt $ createTable table
    case resp of
         Right response -> sendJson { message: "Created table." }
         Left err -> nextThrow $ err

appSetup :: App
appSetup = do
    useExternal jsonBodyParser

    let success = setConfiguration { endpoint: "http://localhost:7956"
                                   , accessKeyId: "AKID"
                                   , secretAccessKey: "SECRET"
                                   , region: "us-west-2"
                                   , apiVersion: "2012-08-10"
                                   }

    get "/" indexHandler
    delete "/:email" $ deleteHandler
    post "/" $ createHandler
    {--put "/:email" $ send "Update endpoint"--}
    get "/:email" detailHandler
    get "/create-local-db" createLocalDbHandler

main :: Effect Server
main = do
    listenHttp appSetup 8080 \_ ->
        log $ "Listening on " <> show 8080

module Main where

import Prelude hiding (apply)
import Data.Maybe (Maybe(..))
import Data.Either (Either(..))
import Data.Array (head)
import Effect (Effect)
import Effect.Console (log)
import Effect.Aff (attempt)
import Effect.Aff.Class (liftAff)
import Effect.Exception (Error, error, message)
import Node.Express.App (App, listenHttp, useExternal, get, post, put, delete)
import Node.Express.Response (send, sendJson, setStatus)
import Node.Express.Handler (Handler, nextThrow)
import Node.Express.Request (getBodyParam, getRouteParam)
import Node.HTTP (Server)
import Dynamo (setConfiguration, createTable, putDoc, scanDoc, deleteDoc, queryDoc)
{--import Debug.Trace (traceM)--}
import ExpressMiddleware (jsonBodyParser)


--Handlers
indexHandler :: Handler
indexHandler = do
    let filters = {}
    resp <- liftAff $ attempt $ scanDoc { "TableName": "employees" } filters
    case resp of
        Right response -> sendJson $ response
        Left err -> nextThrow $ err


createHandler :: Handler
createHandler = do
    emailParam <- getBodyParam "email"
    companyParam <- getBodyParam "company"

    case [emailParam, companyParam] of
         [Just email, Just company] -> do
            let model = { "email": email, "company": company }
            resp <- liftAff $ attempt $ putDoc { "TableName": "employees" } model

            case resp of
                Left err -> do
                    setStatus 500
                    sendJson { message: err }
                Right _ -> do
                    setStatus 201
                    sendJson $ model
         _ -> do
            setStatus 500
            sendJson { message: "Missing values" }

deleteHandler :: Handler
deleteHandler = do
    emailParam <- getRouteParam "email"
    case emailParam of
        Just email -> do
            employeesResp <- liftAff $ attempt $ queryDoc { "TableName": "employees" } { "KeyConditionExpression": "email = :email"
                                                                                       , "ExpressionAttributeValues": {
                                                                                            ":email": email
                                                                                            }
                                                                                        }
            case employeesResp of
                Right employees -> do
                    let employeeMaybe = head $ employees
                    case employeeMaybe of
                         Just x -> do
                            resp <- liftAff $ attempt $ deleteDoc { "TableName": "employees" } { email: x.email, company: x.company }

                            setStatus 200
                            sendJson $ {}

                         Nothing -> do
                            setStatus 400
                            sendJson {}

                Left err -> do
                    setStatus 400
                    sendJson {}

        _ -> do
            setStatus 404
            sendJson {}

detailHandler :: Handler
detailHandler = do
    emailParam <- getRouteParam "email"
    case emailParam of
        Just email -> do
            employeesResp <- liftAff $ attempt $ queryDoc { "TableName": "employees" } { "KeyConditionExpression": "email = :email"
                                                                                       , "ExpressionAttributeValues": {
                                                                                            ":email": email
                                                                                            }
                                                                                        }

            case employeesResp of
                Right employees -> do
                    let employeeMaybe = head $ employees
                    case employeeMaybe of
                        Just x -> do
                            setStatus 200
                            sendJson $ x
                        Nothing -> do
                           setStatus 404
                           sendJson {}

                Left err -> do
                    setStatus 404
                    sendJson {}
        _ -> do
            setStatus 404
            sendJson {}

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
         Right response -> do
            sendJson { message: "Created table." }
         Left err -> do
            setStatus 500
            sendJson { message: err }


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
    get "/create-local-db" createLocalDbHandler
    delete "/:email" $ deleteHandler
    post "/" $ createHandler
    put "/:email" $ send "Update endpoint"
    get "/:email" detailHandler


main :: Effect Server
main = do
    listenHttp appSetup 8080 \_ ->
        log $ "Listening on " <> show 8080

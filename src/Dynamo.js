"use strict"

var AWS = require("aws-sdk");

exports.setConfigurationImpl = function(conf) {
    AWS.config.update(conf);
    return true
}

exports.createTableImpl = function(params) {
    return function (onError, onSuccess) {
        var dynamodb = new AWS.DynamoDB();
        var emptyParams = {
            TableName: "",
            KeySchema: [],
            AttributeDefinitions: [],
            ProvisionedThroughput: {
                ReadCapacityUnits: 5,
                WriteCapacityUnits: 5
            }
        };

        params = Object.assign({}, emptyParams, params);
        dynamodb.createTable(params, function(err, data) {
            if (err) return onError(err + err.stack);
            onSuccess(data);
        })
    }
}

exports.putDocImpl = function(config) {
    return function(item) {
        return function (onError, onSuccess) {
            var docClient = new AWS.DynamoDB.DocumentClient();
            var model = Object.assign({}, config, { Item: item });
            docClient.put(model, function(err, data) {
                if (err) return onError(err + err.stack);
                onSuccess(data);
            });
        }
    }
}

exports.scanDocImpl = function(config) {
    return function(params) {
        return function (onError, onSuccess) {
            var docClient = new AWS.DynamoDB.DocumentClient();
            var model = Object.assign({}, config, params);
            docClient.scan(model, function(err, data) {
                if (err) return onError(err + err.stack);
                onSuccess(data.Items);
            });
        }
    }
}

exports.deleteDocImpl = function(config) {
    return function(params) {
        return function (onError, onSuccess) {
            var docClient = new AWS.DynamoDB.DocumentClient();
            var model = Object.assign({}, config, { Key: params });
            docClient.delete(model, function(err, data) {
                if (err) return onError(err + err.stack);
                onSuccess(data.Items);
            });
        }
    }
}

exports.queryDocImpl = function(config) {
    return function(params) {
        return function (onError, onSuccess) {
            var docClient = new AWS.DynamoDB.DocumentClient();
            var model = Object.assign({}, config, params);
            docClient.query(model, function(err, data) {
                if (err) return onError(err + err.stack);
                onSuccess(data.Items);
            });
        }
    }
}

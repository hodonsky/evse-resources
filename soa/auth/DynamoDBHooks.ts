"use strict"

import {
  DeleteItemCommand,
  DeleteItemCommandOutput,
  DynamoDBClient,
  GetItemCommand,
  GetItemCommandOutput,
  PutItemCommand,
  PutItemCommandOutput,
  QueryCommand,
  QueryCommandOutput,
  ScanCommand,
  ScanCommandOutput,
  UpdateCommand,
  UpdateCommandOutput
} from "@aws-sdk/client-dynamodb"
import { awsConfig, dynamodbConfig } from "./config"

/**
 * Hooks to DynamoDB
 */
export default class DynamoDBHooks {
  docClient:any
  /**
   * Constructor
   */
  constructor(){
    this.docClient = new DynamoDBClient({ ...dynamodbConfig, region: awsConfig.region })
  }

  /**
   * Sends data into DynamoDB
   * @param {string} table - the table in which to put the item
   * @param {Object} putItem - the item to put into the table
   * @returns {Promise<string>} the response message from DynamoDB
   */
  async put( table, putItem ): Promise<PutItemCommandOutput>{
    try {
      return await this.docClient.send(
        new PutItemCommand(
          { TableName: table, Item: putItem }
        )
      )
    } catch ( error ){
      throw {
        name   : `DynamoHooks::put:${error.name}`,
        message: error.message
      }
    }
  }

  /**
   * Gets data from DynamoDB
   * @param {string} table - the table from which to get the item
   * @param {Object} key - the key to get the item
   * @returns {Promise<string>} the item retrieved from DynamoDB
   */
  async get( table, key ):Promise<GetItemCommandOutput> {
    try {
      return await this.docClient.send(
        new GetItemCommand(
          { TableName: table, Key: key }
        )
      )
    } catch ( error ){
      throw {
        name   : `DynamoHooks::get:${error.name}`,
        message: error.message
      }
    }
  }

  /**
   * Deletes data from DynamoDB
   * @param {string} table - the table from which to delete the item
   * @param {Object} key - the key of the item to delete
   * @returns {Promise<string>} the response message from DynamoDB
   */
  async dynamoDelete( table, key ):Promise<DeleteItemCommandOutput>{
    try {
      return await this.docClient.send(
        new DeleteItemCommand(
          { TableName: table, Key: key }
        )
      )
    } catch ( error ){
      throw {
        name   : `DynamoHooks::dynamoDelete:${error.name}`,
        message: error.message
      }
    }
  }

  /**
   * Queries data in DynamoDB
   * @param {string} table - the table from which to query the item
   * @param {string} keyConditionExpression
   * @param {Object} expressionAttributeNames
   * @param {Object} attributeVals
   * @param {string} projectionExpression
   * @returns {Promise<string>} the items from DynamoDB matching the query
   */
  async query( table, keyConditionExpression, expressionAttributeNames,
    attributeVals, projectionExpression ): Promise<QueryCommandOutput>{
    const params = {
      TableName                : table,
      ProjectionExpression     : projectionExpression,
      KeyConditionExpression   : keyConditionExpression,
      ExpressionAttributeNames : expressionAttributeNames,
      ExpressionAttributeValues: attributeVals
    }

    try {
      return await this.docClient.send(
        new QueryCommand(
          params
        )
      )
    } catch ( error ){
      throw {
        name   : `DynamoHooks::query:${error.name}`,
        message: error.message
      }
    }
  }

  /**
   * Scans data in DynamoDB
   * @param {string} table - the table from which to scan the data
   * @param {string} filter
   * @param {Object} attributeVals
   * @returns {Promise<string>} the items from DynamoDB matching the parameters
   */
  async scan( table, filter, attributeVals ): Promise<ScanCommandOutput>{
    const params = {
      TableName                : table,
      FilterExpression         : filter,
      ExpressionAttributeValues: attributeVals
    }

    try {
      return await this.docClient.send( 
        new ScanCommand( params )
      )
    } catch ( error ){
      throw {
        name   : `DynamoHooks::scan:${error.name}`,
        message: error.message
      }
    }
  }

  /**
   * Updates data in DynamoDB
   * @param {Object} params - the parameters to update the DB with
   * @returns {Promise<string>} the response message from DynamoDB
   */
  async update( params ): Promise<UpdateCommandOutput>{
    try {
      return await this.docClient.send( 
        new UpdateCommand( params )
      )
    } catch ( error ){
      throw {
        name   : `DynamoHooks::update:${error.name}`,
        message: error.message
      }
    }
  }
}
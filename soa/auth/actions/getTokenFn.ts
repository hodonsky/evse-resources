"use strict"

import sha256 from "sha256"
import njwt from "njwt"

import DynamoDB from "../DynamoDBHooks"
import config from "../config"

const JTI_TOKEN_TABLE = "JTI_Tokens"
const USER_CREDENTIALS_TABLE = "UserCredentials"

const dynamoDocClient = new DynamoDB()

export default async function({ username, password }) {
  const passwordHash = sha256.x2( password )
  const errorPrefix = "Authentication::credentials:"

  try {
    const data = await dynamoDocClient.get( USER_CREDENTIALS_TABLE, { email: username })
    if ( JSON.stringify( data ) === "{}" ) {
      throw {
        name     : `${errorPrefix}[validation]`,
        message  : "Bad username or password",
        status   : 401,
        userError: true
      }
    } else {
      const { Item: { passwordHash: hash, uuid, active } } = data

      if ( !active ) {
        throw {
          name     : `${errorPrefix}[user_inactive]`,
          message  : "User not active",
          status   : 401,
          userError: true
        }
      }
      if ( hash !== passwordHash ) {
        throw {
          name     : `${errorPrefix}[password_validation]`,
          message  : "Bad username or password",
          status   : 401,
          userError: true
        }
      } else {
        try {
          const jwt = njwt.create({
            issuer : "AuthService",
            subject: uuid,
            scope  : "0b0100"
          }, config.secret )

          jwt.setExpiration()
          try {
            const expiration = new Date().getTime() + ( 60 * 60 * 24000 )
            const expirationEpoch = Math.ceil( expiration / 1000 )
            await dynamoDocClient.put(
              JTI_TOKEN_TABLE,
              { uuid, token: jwt.body.jti, expiration, expirationEpoch }
            )
          } catch ( error ){
            console.error( error )
            throw {
              name   : "Authentication::recordJWT:[dynamoDocClient.put]",
              message: error.message,
              stack  : error.stack,
              status : 500
            }
          }
          return { token: jwt.compact() }
        } catch ( error ) {
          throw {
            name   : error.name ? error.name : `${errorPrefix}njwt.create[User.getAclById]`,
            message: error.message,
            status : error.status || 500
          }
        }
      }
    }
  } catch ( err ){
    console.log( err )
    throw {
      name   : err.name ? err.name : `${errorPrefix}docClient[get]`,
      message: err.message,
      status : err.status || 500
    }
  }
}
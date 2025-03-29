"use strict"

import lambda from "./authTokenFn"
import config from "../config"

export default {
  topic: config.topic,
  action: "authToken",
  lambda,
  requestTransformers: [
    ({ headers: { authorization } }) => ({ token: authorization })
  ],
  responseTransformers: [
    ({ response: { authorized } } ) => {
      if ( !authorized ) {
        throw {
          error: "You're not authorized to do that silly",
          status: 401,
          userError: true
        }
      }
      return { authorized }
    }
  ],
  requestAVRO: [
    { name: "token", type: "string" }
  ],
  responseAVRO: [
    { name: "authorized", type: "boolean" }
  ]
}
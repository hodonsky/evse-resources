"use strict"

import { v4 } from "uuid"

export default {
  topic        : "auth",
  apiCertPrefix: "CERT",
  secret       : process.env.AUTHENTICATION_SECRET || v4()
}

export const awsConfig = {
  accessKeyId    : process.env.AWS_ACCESS_KEY,
  secretAccessKey: process.env.AWS_ACCESS_SECRET,
  region         : process.env.AWS_REGION,
  httpOptions    : {
    // 5 minute timeout
    timeout: 300000
  }
}

export const dynamodbConfig = {
  endpoint       : process.env.DYNAMODB_URL,
  accessKeyId    : process.env.DYNAMODB_ACCESS_KEY,
  secretAccessKey: process.env.DYNAMODB_ACCESS_SECRET
}
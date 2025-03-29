"use strict"

import lambda from "./getEmailFn"
import config from "../config"

export default {
  topic: config.topic,
  action: "getEmail",
  lambda,
  requestTransformers: [
    ({ params: { userId } }) => ({ id: userId })
  ],
  responseTransformers: [
    ({response:{ email }}) => ({ email })
  ],
  requestAVRO: [
    { name: "id", type: "string" }
  ],
  responseAVRO: [
    { name: "email", type: "string" }
  ]
}
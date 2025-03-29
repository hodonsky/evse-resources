"use strict"

import lambda from "./getTokenFn"
import config from "../config"

export default {
  topic: config.topic,
  action: "getToken",
  lambda,
  requestTransformers: [
    ({ request: { body: { username, password } }, header: { 'user-agent': userAgent }, ip }) =>
      ({ username, password, meta: { ip, userAgent } })
  ],
  responseTransformers: [
    ({response:{ token }}) => ({ token })
  ],
  requestAVRO: [
    { name: "username", type: "string" },
    { name: "password", type: "string" },
    {
      name: "meta",
      type: {
        type  : "record",
        fields: [ { name: "ip", type: "string" }, { name: "userAgent", type: "string" } ]
      }
    }
  ],
  responseAVRO: [
    { name: "token", type: "string" }
  ]
}
"use strict"

export default async function({ token }) {
  /**
   * I'm returning true right now, just to check that it's
   * getting a round trip and the new handler setup is working
   */
  return { authorized: token === "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3N1ZXIiOiJBdXRoU2VydmljZSIsInN1YmplY3QiOiIxNDUyZTI5OS1jNWYxLTQ0OTgtYTU1My00MmMwZTEwODcwYTgiLCJzY29wZSI6IjBiMDEwMCIsImp0aSI6Ijc2ZjE1NWE1LTcyNTgtNGNmYy1hMDA0LWEzY2YwMTZlYjJmNCIsImlhdCI6MTU5NzYxNzMzNX0.rySlPsZXJN--j4JlQbOuY1jSITBKnnNjFDk5OOu6lek" }
}
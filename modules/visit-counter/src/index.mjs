// Visitor counter behind CloudFront at /api/visit.
//   GET  /api/visit -> { "count": N }        read the total
//   POST /api/visit -> { "count": N + 1 }    count a new visitor
// The page only POSTs once per browser, so the total counts browsers, not page views.
import { DynamoDBClient, GetItemCommand, UpdateItemCommand } from "@aws-sdk/client-dynamodb";

const db = new DynamoDBClient({});
const TABLE_NAME = process.env.TABLE_NAME;
const KEY = { id: { S: "visits" } };

const json = (statusCode, body, extraHeaders = {}) => ({
  statusCode,
  headers: {
    "content-type": "application/json",
    "cache-control": "no-store",
    ...extraHeaders,
  },
  body: JSON.stringify(body),
});

export const handler = async (event) => {
  const method = event.requestContext?.http?.method;
  const path = event.rawPath;

  if (path !== "/api/visit") {
    return json(404, { error: "not found" });
  }

  try {
    if (method === "GET" || method === "HEAD") {
      const { Item } = await db.send(new GetItemCommand({ TableName: TABLE_NAME, Key: KEY }));
      return json(200, { count: Number(Item?.count?.N ?? 0) });
    }

    if (method === "POST") {
      // ADD is atomic: concurrent visits never overwrite each other.
      const { Attributes } = await db.send(
        new UpdateItemCommand({
          TableName: TABLE_NAME,
          Key: KEY,
          UpdateExpression: "ADD #count :one",
          ExpressionAttributeNames: { "#count": "count" },
          ExpressionAttributeValues: { ":one": { N: "1" } },
          ReturnValues: "UPDATED_NEW",
        }),
      );
      return json(200, { count: Number(Attributes.count.N) });
    }

    return json(405, { error: "method not allowed" }, { allow: "GET, HEAD, POST" });
  } catch (err) {
    console.error(err);
    return json(500, { error: "internal error" });
  }
};

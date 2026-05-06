const http = require("http");

const port = Number(process.env.PORT || 8080);
const serviceName = process.env.SERVICE_NAME || "mock-backend";
const environment = process.env.APP_ENV || "dev";
const dbHost = process.env.DB_HOST || "";
const dbName = process.env.DB_NAME || "mockapp";

const items = [
  {
    id: 1,
    title: "Terraform dev infrastructure",
    status: "completed",
  },
  {
    id: 2,
    title: "Argo CD platform sync",
    status: "completed",
  },
  {
    id: 3,
    title: "Frontend and backend app flow",
    status: "in-progress",
  },
];

function sendJson(response, statusCode, payload) {
  const body = JSON.stringify(payload);

  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Access-Control-Allow-Origin": "*",
  });
  response.end(body);
}

function sendText(response, statusCode, payload) {
  response.writeHead(statusCode, {
    "Content-Type": "text/plain; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(payload);
}

const server = http.createServer((request, response) => {
  const url = new URL(request.url, `http://${request.headers.host}`);

  if (request.method === "OPTIONS") {
    response.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    });
    response.end();
    return;
  }

  if (request.method !== "GET") {
    sendJson(response, 405, {
      error: "method_not_allowed",
    });
    return;
  }

  if (url.pathname === "/" || url.pathname === "/api" || url.pathname === "/api/health") {
    sendJson(response, 200, {
      service: serviceName,
      status: "ok",
      environment,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  if (url.pathname === "/api/status") {
    sendJson(response, 200, {
      service: serviceName,
      environment,
      database: {
        hostConfigured: Boolean(dbHost),
        host: dbHost,
        name: dbName,
      },
      kubernetes: {
        runtime: "Amazon EKS",
        delivery: "Argo CD / GitOps ready",
      },
    });
    return;
  }

  if (url.pathname === "/api/items") {
    sendJson(response, 200, {
      items,
    });
    return;
  }

  if (url.pathname === "/healthz") {
    sendText(response, 200, "ok");
    return;
  }

  sendJson(response, 404, {
    error: "not_found",
    path: url.pathname,
  });
});

server.listen(port, "0.0.0.0", () => {
  console.log(`${serviceName} listening on ${port}`);
});


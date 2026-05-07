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

const events = [];

function sendJson(response, statusCode, payload) {
  const body = JSON.stringify(payload);

  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Access-Control-Allow-Origin": "*",
  });
  response.end(body);
}

function logRequest(request, statusCode) {
  console.log(
    JSON.stringify({
      type: "http_request",
      method: request.method,
      path: new URL(request.url, `http://${request.headers.host}`).pathname,
      statusCode,
      timestamp: new Date().toISOString(),
    }),
  );
}

function sendLoggedJson(request, response, statusCode, payload) {
  logRequest(request, statusCode);
  sendJson(response, statusCode, payload);
}

function readBody(request) {
  return new Promise((resolve, reject) => {
    let body = "";

    request.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1024 * 1024) {
        request.destroy();
        reject(new Error("request_too_large"));
      }
    });

    request.on("end", () => resolve(body));
    request.on("error", reject);
  });
}

function sendText(response, statusCode, payload) {
  response.writeHead(statusCode, {
    "Content-Type": "text/plain; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(payload);
}

const server = http.createServer(async (request, response) => {
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

  if (request.method === "GET" && (url.pathname === "/" || url.pathname === "/api" || url.pathname === "/api/health")) {
    sendLoggedJson(request, response, 200, {
      service: serviceName,
      status: "ok",
      environment,
      timestamp: new Date().toISOString(),
    });
    return;
  }

  if (request.method === "GET" && url.pathname === "/api/status") {
    sendLoggedJson(request, response, 200, {
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
      interactions: {
        totalEvents: events.length,
        lastEvent: events.at(-1) || null,
      },
    });
    return;
  }

  if (request.method === "GET" && url.pathname === "/api/items") {
    sendLoggedJson(request, response, 200, {
      items,
    });
    return;
  }

  if (request.method === "POST" && url.pathname === "/api/events") {
    try {
      const rawBody = await readBody(request);
      const payload = rawBody ? JSON.parse(rawBody) : {};
      const event = {
        id: events.length + 1,
        source: payload.source || "frontend",
        action: payload.action || "manual-test",
        receivedAt: new Date().toISOString(),
      };

      events.push(event);
      console.log(JSON.stringify({ type: "demo_event", ...event }));
      sendLoggedJson(request, response, 201, {
        accepted: true,
        event,
        totalEvents: events.length,
      });
    } catch (error) {
      sendLoggedJson(request, response, 400, {
        error: "invalid_request",
        message: error.message,
      });
    }
    return;
  }

  if (request.method === "GET" && url.pathname === "/healthz") {
    sendText(response, 200, "ok");
    return;
  }

  sendLoggedJson(request, response, request.method === "GET" ? 404 : 405, {
    error: "not_found",
    path: url.pathname,
  });
});

server.listen(port, "0.0.0.0", () => {
  console.log(`${serviceName} listening on ${port}`);
});

const apiStatus = document.querySelector("#apiStatus");
const dbStatus = document.querySelector("#dbStatus");
const taskList = document.querySelector("#taskList");
const responseBox = document.querySelector("#responseBox");
const refreshButton = document.querySelector("#refreshButton");
const sendEventButton = document.querySelector("#sendEventButton");
const eventStatus = document.querySelector("#eventStatus");

function setText(element, value) {
  element.textContent = value;
}

function renderTasks(items) {
  taskList.innerHTML = "";

  for (const item of items) {
    const row = document.createElement("li");
    const title = document.createElement("span");
    const status = document.createElement("strong");

    title.textContent = item.title;
    status.textContent = item.status;

    row.append(title, status);
    taskList.append(row);
  }
}

async function loadDashboard() {
  setText(apiStatus, "Checking");
  setText(dbStatus, "Checking");
  refreshButton.disabled = true;

  try {
    const [statusResponse, itemsResponse] = await Promise.all([
      fetch("/api/status", { cache: "no-store" }),
      fetch("/api/items", { cache: "no-store" }),
    ]);

    if (!statusResponse.ok || !itemsResponse.ok) {
      throw new Error("API returned an unsuccessful status");
    }

    const statusPayload = await statusResponse.json();
    const itemsPayload = await itemsResponse.json();

    setText(apiStatus, "Healthy");
    setText(dbStatus, statusPayload.database.hostConfigured ? "Configured" : "Missing");
    renderTasks(itemsPayload.items);
    responseBox.textContent = JSON.stringify(statusPayload, null, 2);
  } catch (error) {
    setText(apiStatus, "Unavailable");
    setText(dbStatus, "Unknown");
    taskList.innerHTML = "";
    responseBox.textContent = error.message;
  } finally {
    refreshButton.disabled = false;
  }
}

async function sendDemoEvent() {
  sendEventButton.disabled = true;
  setText(eventStatus, "Sending event to backend");

  try {
    const response = await fetch("/api/events", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        source: "frontend-ui",
        action: "button-click",
      }),
    });

    if (!response.ok) {
      throw new Error("Backend rejected the event");
    }

    const payload = await response.json();
    setText(eventStatus, `Accepted event #${payload.event.id} at ${payload.event.receivedAt}`);
    await loadDashboard();
  } catch (error) {
    setText(eventStatus, error.message);
  } finally {
    sendEventButton.disabled = false;
  }
}

refreshButton.addEventListener("click", loadDashboard);
sendEventButton.addEventListener("click", sendDemoEvent);
loadDashboard();

const apiStatus = document.querySelector("#apiStatus");
const dbStatus = document.querySelector("#dbStatus");
const taskList = document.querySelector("#taskList");
const responseBox = document.querySelector("#responseBox");
const refreshButton = document.querySelector("#refreshButton");

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

refreshButton.addEventListener("click", loadDashboard);
loadDashboard();


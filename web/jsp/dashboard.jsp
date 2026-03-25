<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="jakarta.servlet.http.*, jakarta.servlet.*, java.util.*" %>
<%
    if (session == null || session.getAttribute("userId") == null || session.getAttribute("name") == null) {
        response.sendRedirect("login.html");
        return;
    }

    String username = (String) session.getAttribute("name");
    List<Map<String, String>> todayMedicines = (List<Map<String, String>>) request.getAttribute("todayMedicines");
    List<Map<String, Object>> missedDoses = (List<Map<String, Object>>) request.getAttribute("missedDoses");
    String todayDate = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <!-- <meta http-equiv="refresh" content="70"> Auto-refresh every 30 seconds-->
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>HealSync Dashboard</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="css/styles.css">
</head>
<body class="dashboard-page">
  <aside class="sidebar">
    <div class="logo">
      <img src="images/healsync_logo.png" width="50px" alt="HealSync Logo" class="logo-img" /> HealSync
    </div>
    <nav class="nav">
      <a href="dashboard">Dashboard</a>
      <a href="AddMedicine.html">Add Medicine</a>
      <a href="myMedicines">View My Medicines</a>
      <a href="pdfReport">PDF Report</a>
      <a href="logout">Logout</a>
    </nav>
  </aside>

  <main class="main"> 
    <div class="header">Welcome <%= username %> 👋</div>

    <div class="cards">
      <div class="card">
        <h3>Upcoming Doses</h3>
        <p>You have <%= todayMedicines != null ? todayMedicines.size() : 0 %> doses scheduled for today.</p>
      </div>
      <a href="AddMedicine.html" class="card-link">
        <div class="card">
          <h3>Add New Medicine</h3>
          <p>Click to schedule a new medicine reminder.</p>
        </div>
      </a>
      <a href="myMedicines" class="card-link">
        <div class="card">
          <h3>View My Medicines</h3>
          <p>See all your scheduled medicines in one place.</p>
        </div>
      </a>
      <div class="card">
        <h3>Missed Doses</h3>
        <p><%= missedDoses != null ? missedDoses.size() : 0 %> dose(s) missed today.</p>
      </div>
      <div class="card" onclick="window.location.href='./pdfReport'">
        <h3>Generate PDF Report</h3>
        <p>Download your dosage history.</p>
      </div>
        <div class="card" onclick="window.location.href='./doseHistory'">
        <h3>All Dose History</h3>
        <p>View all your taken, skipped, and missed doses.</p>
  </div>

    </div>

    <div class="medicine-reminders">
      <h3>Today's Medicines:</h3>
      <ul id="medicine-list">
        <% if (todayMedicines != null && !todayMedicines.isEmpty()) {
              for (Map<String, String> med : todayMedicines) { %>
            <li><%= med.get("name") %> at <%= med.get("time") %></li>
        <%   }
           } else { %>
            <li>No medicines scheduled for today.</li>
        <% } %>
      </ul>
    </div>

    <div class="missed-doses">
      <h3>Doses Status:</h3>
      <ul>
        <% if (missedDoses != null && !missedDoses.isEmpty()) {
              for (Map<String, Object> dose : missedDoses) {
                  String statusClass = "";
                  String status = (String) dose.get("status");
                  if ("TAKEN".equals(status)) statusClass = "status-taken";
                  else if ("SKIPPED".equals(status)) statusClass = "status-skipped";
                  else if ("MISSED".equals(status)) statusClass = "status-missed";
        %>
           <li class="<%= statusClass %>" 
    data-name="<%= dose.get("name") %>" 
    data-time="<%= dose.get("time") %>" 
    data-date="<%= dose.get("eventDate") %>">
    
  <span class="dose-text">
    <%= dose.get("name") %> at <%= dose.get("time") %> 
    (<%= dose.get("eventDate") %>) - <span class="dose-status"><%= status %></span>
  </span>

</li>
        <%   }
           } else { %>
            <li>No missed doses today 🎉</li>
        <% } %>  
      </ul>
    </div>
  </main>
<script>
// ============================================
// MEDICINE REMINDER SYSTEM - PRODUCTION CODE
// ============================================

// Initialize medicines array from JSP backend
const todayMeds = [];
<% 
    String safeUsername = "";
    if (username != null) {
        safeUsername = username.replace("\\", "\\\\").replace("\"", "\\\"").replace("'", "\\'");
    }
%>
const pageUserName = "<%= safeUsername %>"; // user account name guard
<% 
    if (todayMedicines != null && !todayMedicines.isEmpty()) {
        for (Map<String, String> med : todayMedicines) {
            String name = med.get("name");
            String time = med.get("time");
%>
    {
        const itemName = '<%= name %>'.trim();
        const itemTime = '<%= time %>'.trim().substring(0, 5);

        if (!itemName || !itemTime || itemName === pageUserName) {
            console.warn("Skipping invalid medicine record:", itemName, itemTime);
        } else {
            todayMeds.push({
                name: itemName,
                time: itemTime,
                status: 'PENDING',
                notified: false,
                alarmTimeout: null
            });
        }
    }
<% 
        }
    }
%>

// Audio & Notification Setup
const alarmAudio = new Audio("sounds/alarm.mp3");
alarmAudio.volume = 1.0;

if (Notification.permission !== "granted") {
    Notification.requestPermission();
}

// GUI State
let currentMed = null;

// ============================================
// CREATE POPUP UI
// ============================================
const popup = document.createElement("div");
popup.id = "medicinePopup";
popup.style.position = "fixed";
popup.style.top = "50%";
popup.style.left = "50%";
popup.style.transform = "translate(-50%, -50%)";
popup.style.padding = "25px";
popup.style.background = "#ffffff";
popup.style.borderRadius = "15px";
popup.style.boxShadow = "0 10px 25px rgba(0,0,0,0.3)";
popup.style.display = "none";
popup.style.zIndex = "9999";
popup.style.textAlign = "center";
popup.style.width = "300px";
popup.style.fontFamily = "Arial, sans-serif";
document.body.appendChild(popup);

const popupMessage = document.createElement("div");
popupMessage.style.marginBottom = "20px";
popupMessage.style.fontSize = "18px";
popupMessage.style.fontWeight = "600";
popup.appendChild(popupMessage);

const btnContainer = document.createElement("div");
btnContainer.style.display = "flex";
btnContainer.style.justifyContent = "space-between";
popup.appendChild(btnContainer);

// Taken Button
const takenBtn = document.createElement("button");
takenBtn.innerText = "Taken";
takenBtn.style.flex = "1";
takenBtn.style.marginRight = "10px";
takenBtn.style.padding = "10px";
takenBtn.style.border = "none";
takenBtn.style.borderRadius = "8px";
takenBtn.style.background = "#28a745";
takenBtn.style.color = "#fff";
takenBtn.style.cursor = "pointer";
takenBtn.style.fontWeight = "600";

// Skip Button
const skipBtn = document.createElement("button");
skipBtn.innerText = "Skip";
skipBtn.style.flex = "1";
skipBtn.style.padding = "10px";
skipBtn.style.border = "none";
skipBtn.style.borderRadius = "8px";
skipBtn.style.background = "#dc3545";
skipBtn.style.color = "#fff";
skipBtn.style.cursor = "pointer";
skipBtn.style.fontWeight = "600";

btnContainer.appendChild(takenBtn);
btnContainer.appendChild(skipBtn);

// ============================================
// UI UPDATE FUNCTION - ALWAYS CREATES NEW LI
// ============================================
function updateDoseStatusUI(name, time, status) {
    // Strict validation - no updates if invalid
    if (!name || !time || !status || typeof name !== 'string' || typeof time !== 'string' || typeof status !== 'string') {
        console.warn("updateDoseStatusUI: Invalid input - skipping update", { name, time, status });
        return;
    }

    const safeName = name.trim();
    const safeTime = time.trim().substring(0, 5);  // Ensure HH:mm format
    const safeStatus = status.trim();

    if (!safeName || !safeTime || !safeStatus) {
        console.warn("updateDoseStatusUI: Empty values after trim - skipping update", { safeName, safeTime, safeStatus });
        return;
    }

    console.log("updateDoseStatusUI: Creating new LI", { safeName, safeTime, safeStatus });

    // Always create a new <li> element
    const ul = document.querySelector(".missed-doses ul");
    if (!ul) {
        console.error("updateDoseStatusUI: .missed-doses ul not found");
        return;
    }

    const li = document.createElement("li");
    li.setAttribute("data-name", safeName);
    li.setAttribute("data-time", safeTime);

    // Add status class
    if (safeStatus === "TAKEN") li.classList.add("status-taken");
    else if (safeStatus === "SKIPPED") li.classList.add("status-skipped");
    else if (safeStatus === "MISSED") li.classList.add("status-missed");

    // Set safe DOM text with proper format: "MedicineName at HH:mm (Today) - STATUS"
    const span = document.createElement("span");
    span.classList.add("dose-text");

    const statusText = document.createElement("span");
    statusText.classList.add("dose-status");
    statusText.textContent = safeStatus;

    // Use string concatenation instead of template literal to avoid JSP EL conflict
    const textContent = safeName + " at " + safeTime + " (Today) - ";
    span.appendChild(document.createTextNode(textContent));
    span.appendChild(statusText);

    li.appendChild(span);

    // Append to the list
    ul.appendChild(li);
}

// ============================================
// HELPER FUNCTIONS
// ============================================
function getMedicineByNameAndTime(name, time) {
    if (!name || !time) return null;
    const cleanName = name.trim();
    const cleanTime = time.trim().substring(0, 5);
    
    return todayMeds.find(m =>
        m.name.trim() === cleanName &&
        m.time.trim() === cleanTime
    );
}

function showPopup(name, time) {
    // Guard: validate inputs
    if (!name || !time) {
        console.error("showPopup: Invalid medicine data", { name, time });
        return;
    }

    if (name.trim() === pageUserName) {
        console.error("showPopup: Medicine name equals username, ignoring", { name, time });
        return;
    }

    popupMessage.textContent = "⏰ Time to take " + name.trim();
    popup.style.display = "block";

    // Store clean references only (primitives, not objects)
    currentMed = {
        name: name.trim(),
        time: time.trim().substring(0, 5)
    };
}

function hidePopup() {
    popup.style.display = "none";
}

function stopAlarm() {
    alarmAudio.pause();
    alarmAudio.currentTime = 0;
}

// ============================================
// BACKEND COMMUNICATION
// ============================================
function logDose(name, time, status) {
    if (!name || !time || !status) {
        console.error("logDose: Invalid parameters", { name, time, status });
        return;
    }

    fetch("<%= request.getContextPath() %>/doseStatus", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: "medicineName=" + encodeURIComponent(name.trim()) +
              "&medTime=" + encodeURIComponent(time.trim().substring(0, 5)) +
              "&status=" + encodeURIComponent(status)
    })
    .then(response => {
        console.log("✅ Dose logged to backend:", { name, time, status });
    })
    .catch(err => console.error("❌ Failed to log dose:", err));
}

// ============================================
// BUTTON EVENT LISTENERS
// ============================================
takenBtn.addEventListener("click", () => {
    stopAlarm();
    hidePopup();

    if (!currentMed) {
        console.warn("No medicine in popup");
        return;
    }

    const med = getMedicineByNameAndTime(currentMed.name, currentMed.time);
    if (!med) {
        console.error("Medicine not found in todayMeds:", currentMed);
        return;
    }

    // Clear any pending timeout
    if (med.alarmTimeout) {
        clearTimeout(med.alarmTimeout);
        med.alarmTimeout = null;
    }

    // Update state
    med.status = "TAKEN";
    med.notified = true;

    // Update backend and UI (pass primitives only)
    logDose(med.name, med.time, "TAKEN");
    updateDoseStatusUI(med.name, med.time, "TAKEN");

    console.log("✅ Dose marked as TAKEN:", { name: med.name, time: med.time });
});

skipBtn.addEventListener("click", () => {
    stopAlarm();
    hidePopup();

    if (!currentMed) {
        console.warn("No medicine in popup");
        return;
    }

    const med = getMedicineByNameAndTime(currentMed.name, currentMed.time);
    if (!med) {
        console.error("Medicine not found in todayMeds:", currentMed);
        return;
    }

    // Clear any pending timeout
    if (med.alarmTimeout) {
        clearTimeout(med.alarmTimeout);
        med.alarmTimeout = null;
    }

    // Update state
    med.status = "SKIPPED";
    med.notified = true;

    // Update backend and UI (pass primitives only)
    logDose(med.name, med.time, "SKIPPED");
    updateDoseStatusUI(med.name, med.time, "SKIPPED");

    console.log("✅ Dose marked as SKIPPED:", { name: med.name, time: med.time });
});

// ============================================
// ALARM SYSTEM
// ============================================
function triggerAlarm(med) {
    if (!med || med.status !== "PENDING") {
        return;  // Only trigger for PENDING status
    }

    // Play audio
    alarmAudio.currentTime = 0;
    alarmAudio.play().catch(() => console.log("Audio playback prevented"));

    // Show popup
    showPopup(med.name, med.time);

    // Send notification
    if (Notification.permission === "granted") {
        new Notification("Medicine Reminder", {
            body: "Time to take " + med.name,
            //icon: "images/icon.png"
        });
    }

    // Set auto-miss timeout (30 seconds)
    med.alarmTimeout = setTimeout(() => {
        stopAlarm();
        hidePopup();

        // Only mark as missed if still pending
        if (med.status === "PENDING") {
            med.status = "MISSED";
            logDose(med.name, med.time, "MISSED");
            updateDoseStatusUI(med.name, med.time, "MISSED");
            console.log("⏳ Dose auto-marked as MISSED:", { name: med.name, time: med.time });
        }
    }, 30000);
}

function checkAndTriggerAlarms() {
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    const currentTimeInMinutes = currentHour * 60 + currentMinute;

    todayMeds.forEach(med => {
        const [medHour, medMinute] = med.time.split(":").map(Number);
        const medTimeInMinutes = medHour * 60 + medMinute;

        // Trigger alarm only if time matches AND status is PENDING AND not already notified
        if (medTimeInMinutes === currentTimeInMinutes && med.status === "PENDING" && !med.notified) {
            med.notified = true;  // Mark as notified immediately to prevent re-trigger
            triggerAlarm(med);
        }
    });
}

// Start alarm check (every 5 seconds)
setInterval(checkAndTriggerAlarms, 5000);

console.log("✅ Medicine Reminder System initialized. Medicines:", todayMeds);
</script>
</body>
</html>

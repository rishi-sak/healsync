<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%
   
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.html");
        return;
    }

    List<Map<String, String>> doseList = (List<Map<String, String>>) request.getAttribute("doseList");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Dose History | HealSync</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body class="dosehistory-page">
    <h2>Dose History</h2>

    <div class="dose-container">
        <% if (doseList != null && !doseList.isEmpty()) {
               for (Map<String, String> dose : doseList) {
                   String statusClass = dose.get("status").toLowerCase();
        %>
        <div class="dose-card">
            <div class="dose-name"><%= dose.get("name") %></div>
            <div class="dose-info"><strong>Time:</strong> <%= dose.get("time") %></div>
            <div class="dose-info">
                <strong>Status:</strong> 
                <span class="status <%= statusClass %>"><%= dose.get("status") %></span>
            </div>
            <div class="dose-info"><strong>Date:</strong> <%= dose.get("date") %></div>
        </div>
        <%   }
           } else { %>
        <div style="grid-column: 1 / -1; text-align:center; color:#666;">No dose history available.</div>
        <% } %>
    </div>

    <a href="dashboard" class="back-btn">← Back to Dashboard</a>
</body>
</html>

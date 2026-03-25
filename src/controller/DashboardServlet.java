package controller;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;

public class DashboardServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        Integer userId = (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        List<Map<String, Object>> todayMedicines = new ArrayList<>();
        List<Map<String, Object>> missedDoses = new ArrayList<>();
        List<Map<String, Object>> doseHistory = new ArrayList<>();

        try {

            Class.forName("com.mysql.cj.jdbc.Driver");

            Connection conn = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/healsync_db",
                    "root",
                    "Admin");

            // --- Today's medicines
            String queryToday = "SELECT ms.medicine_name, mt.med_time " +
                    "FROM medicine_schedule ms " +
                    "JOIN medicine_times mt ON ms.id = mt.medicine_id " +
                    "WHERE ms.user_id = ? " +
                    "AND CURDATE() BETWEEN ms.start_date AND ms.end_date " +
                    "ORDER BY mt.med_time ASC";

            PreparedStatement ps1 = conn.prepareStatement(queryToday);
            ps1.setInt(1, userId);

            ResultSet rs1 = ps1.executeQuery();

            SimpleDateFormat inputFormat = new SimpleDateFormat("HH:mm:ss");
            SimpleDateFormat outputFormat = new SimpleDateFormat("HH:mm");

            while (rs1.next()) {

                Map<String, Object> med = new HashMap<>();

                med.put("name", rs1.getString("medicine_name"));

                String rawTime = rs1.getString("med_time");
                String formattedTime = rawTime;

                try {
                    java.util.Date time = inputFormat.parse(rawTime);
                    formattedTime = outputFormat.format(time);
                } catch (Exception e) {
                    // keep rawTime if parsing fails
                }

                med.put("time", formattedTime);

                todayMedicines.add(med);
            }

            rs1.close();
            ps1.close();

            // --- Missed / Taken / Skipped doses for TODAY ONLY
            String queryMissed = "SELECT medicine_name, med_time, event_date, status " +
                    "FROM dose_logs " +
                    "WHERE user_id = ? " +
                    "AND status IN ('TAKEN', 'MISSED', 'SKIPPED') " +
                    "AND event_date = CURDATE() " +
                    "ORDER BY event_date DESC, med_time ASC";

            PreparedStatement ps2 = conn.prepareStatement(queryMissed);
            ps2.setInt(1, userId);

            ResultSet rs2 = ps2.executeQuery();

            SimpleDateFormat inputTime = new SimpleDateFormat("HH:mm:ss");
            SimpleDateFormat outputTime = new SimpleDateFormat("HH:mm");
            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");

            while (rs2.next()) {

                Map<String, Object> dose = new HashMap<>();

                dose.put("name", rs2.getString("medicine_name"));

                String rawTime = rs2.getString("med_time");
                String formattedTime = rawTime;

                try {
                    java.util.Date time = inputTime.parse(rawTime);
                    formattedTime = outputTime.format(time);
                } catch (Exception e) {
                }

                dose.put("time", formattedTime);
                dose.put("eventDate", dateFormat.format(rs2.getDate("event_date")));
                dose.put("status", rs2.getString("status"));

                missedDoses.add(dose);
            }

            rs2.close();
            ps2.close();

            // --- Dose History (ALL DAYS)
            String queryHistory = "SELECT medicine_name, med_time, event_date, status " +
                    "FROM dose_logs " +
                    "WHERE user_id = ? " +
                    "AND status IN ('TAKEN', 'MISSED', 'SKIPPED') " +
                    "ORDER BY event_date DESC, med_time ASC";

            PreparedStatement ps3 = conn.prepareStatement(queryHistory);
            ps3.setInt(1, userId);

            ResultSet rs3 = ps3.executeQuery();

            while (rs3.next()) {

                Map<String, Object> history = new HashMap<>();

                history.put("name", rs3.getString("medicine_name"));

                String rawTime = rs3.getString("med_time");
                String formattedTime = rawTime;

                try {
                    java.util.Date time = inputTime.parse(rawTime);
                    formattedTime = outputTime.format(time);
                } catch (Exception e) {
                }

                history.put("time", formattedTime);
                history.put("eventDate", dateFormat.format(rs3.getDate("event_date")));
                history.put("status", rs3.getString("status"));

                doseHistory.add(history);
            }

            rs3.close();
            ps3.close();

            conn.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        request.setAttribute("todayMedicines", todayMedicines);
        request.setAttribute("missedDoses", missedDoses);
        request.setAttribute("doseHistory", doseHistory);

        RequestDispatcher dispatcher = request.getRequestDispatcher("web/jsp/dashboard.jsp");
        dispatcher.forward(request, response);
    }

    // --- Handle POST actions for buttons (TAKEN / SKIPPED)
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        Integer userId = (Integer) session.getAttribute("userId");

        String action = request.getParameter("action");
        String medicineName = request.getParameter("medicineName");
        String medTime = request.getParameter("medTime");

        if (action != null && medicineName != null && medTime != null) {

            try {

                Class.forName("com.mysql.cj.jdbc.Driver");

                Connection conn = DriverManager.getConnection(
                        "jdbc:mysql://localhost:3306/healsync_db",
                        "root",
                        "Admin");

                // Prevent overwriting TAKEN/SKIPPED
                String checkQuery = "SELECT status FROM dose_logs WHERE user_id = ? AND medicine_name = ? AND med_time = ? AND event_date = CURDATE()";

                PreparedStatement checkPs = conn.prepareStatement(checkQuery);

                checkPs.setInt(1, userId);
                checkPs.setString(2, medicineName);
                checkPs.setString(3, medTime + ":00");

                ResultSet rs = checkPs.executeQuery();

                boolean canUpdate = true;

                if (rs.next()) {

                    String existingStatus = rs.getString("status");

                    if ("TAKEN".equals(existingStatus)) {
                        canUpdate = false;
                    }
                }

                rs.close();
                checkPs.close();

                if (canUpdate) {

                    String insertLog = "INSERT INTO dose_logs (user_id, medicine_name, med_time, event_date, status) " +
                            "VALUES (?, ?, ?, CURDATE(), ?) " +
                            "ON DUPLICATE KEY UPDATE status = ?";

                    PreparedStatement ps = conn.prepareStatement(insertLog);

                    ps.setInt(1, userId);
                    ps.setString(2, medicineName);
                    ps.setString(3, medTime + ":00");
                    ps.setString(4, action);
                    ps.setString(5, action);

                    ps.executeUpdate();

                    ps.close();
                }

                conn.close();

            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        response.sendRedirect(request.getContextPath() + "/dashboard");
    }
}
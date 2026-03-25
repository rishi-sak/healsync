package controller;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

public class DoseServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null) {
            response.sendRedirect(request.getContextPath() + "login.html");
            return;
        }

        Integer userId = (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect(request.getContextPath() + "login.html");
            return;
        }

        String medicineName = request.getParameter("medicineName");
        String medTime = request.getParameter("medTime"); // expected HH:mm
        String status = request.getParameter("status");   // TAKEN / SKIPPED / MISSED

        if (medicineName == null || medTime == null || status == null) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("Missing parameters");
            return;
        }

        Connection conn = null;
        PreparedStatement ps = null;
        PreparedStatement checkPs = null;
        ResultSet rs = null;

        try {

            Class.forName("com.mysql.cj.jdbc.Driver");

            conn = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/healsync_db",
                    "root",
                    "Admin");

            if (medTime.length() == 5) {
                medTime = medTime + ":00";
            }

            // Step 1: Check existing status
            String checkQuery = "SELECT status FROM dose_logs WHERE user_id=? AND medicine_name=? AND med_time=? AND event_date=CURDATE()";

            checkPs = conn.prepareStatement(checkQuery);

            checkPs.setInt(1, userId);
            checkPs.setString(2, medicineName);
            checkPs.setString(3, medTime);

            rs = checkPs.executeQuery();

            boolean canUpdate = true;

            if (rs.next()) {

                String existingStatus = rs.getString("status");

                // Don't overwrite TAKEN or SKIPPED
                if ("TAKEN".equalsIgnoreCase(existingStatus) || "SKIPPED".equalsIgnoreCase(existingStatus)) {
                    canUpdate = false;
                }
            }

            rs.close();
            checkPs.close();

            // Step 2: Insert / Update if allowed
            if (canUpdate) {

                String upsert = "INSERT INTO dose_logs (user_id, medicine_name, med_time, event_date, status) " +
                        "VALUES (?, ?, ?, CURDATE(), ?) " +
                        "ON DUPLICATE KEY UPDATE status = VALUES(status)";

                ps = conn.prepareStatement(upsert);

                ps.setInt(1, userId);
                ps.setString(2, medicineName);
                ps.setString(3, medTime);
                ps.setString(4, status);

                ps.executeUpdate();
            }

            response.setContentType("text/plain");
            response.getWriter().write("Status updated: " + status);

        } catch (Exception e) {

            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("Error updating dose status.");

        } finally {

            try {
                if (rs != null)
                    rs.close();
            } catch (Exception ignored) {}

            try {
                if (ps != null)
                    ps.close();
            } catch (Exception ignored) {}

            try {
                if (conn != null)
                    conn.close();
            } catch (Exception ignored) {}
        }
    }
}
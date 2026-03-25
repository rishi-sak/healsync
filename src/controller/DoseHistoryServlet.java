package controller;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.*;


public class DoseHistoryServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ✅ Get existing session
        HttpSession session = request.getSession(false);
        if (session == null) {
            response.sendRedirect("login.html");
            return;
        }

        // ✅ Safe retrieval of userId from session (handles Integer or String)
        Object userIdObj = session.getAttribute("userId");
        Integer userId = null;
        System.out.println(">>> Logged in userId from session = " + session.getAttribute("userId"));
        if (userIdObj instanceof Integer) {
            userId = (Integer) userIdObj;
        } else if (userIdObj instanceof String) {
            try {
                userId = Integer.parseInt((String) userIdObj);
            } catch (NumberFormatException e) {
                response.sendRedirect("login.html");
                return;
            }
        }

        if (userId == null) {
            response.sendRedirect("login.html");
            return;
        }

        // ✅ Prepare dose list
        List<Map<String, String>> doseList = new ArrayList<>();

        try {
            // Load driver & connect
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/healsync_db", "root", "Admin");

            // ✅ Correct query for dose_logs table
            String query = "SELECT medicine_name, med_time, status, event_date " +
                    "FROM dose_logs " +
                    "WHERE user_id = ? " +
                    "ORDER BY event_date DESC";

            PreparedStatement ps = con.prepareStatement(query);
            ps.setInt(1, userId); // Integer binding
            ResultSet rs = ps.executeQuery();

            while (rs.next()) {
                Map<String, String> dose = new HashMap<>();
                dose.put("name", rs.getString("medicine_name"));
                dose.put("time", rs.getString("med_time"));
                dose.put("status", rs.getString("status"));
                dose.put("date", rs.getDate("event_date").toString());
                doseList.add(dose);
            }

            rs.close();
            ps.close();
            con.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        // ✅ Forward to JSP
        request.setAttribute("doseList", doseList);
        request.getRequestDispatcher("web/jsp/doseHistory.jsp").forward(request, response);
    }
}

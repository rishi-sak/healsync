package controller;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

public class AddMedicineServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String medicineName = request.getParameter("medicineName");
        String startDate = request.getParameter("startDate");
        String endDate = request.getParameter("endDate");
        String dosageInstructions = request.getParameter("dosageInstructions");
        String reminderType = request.getParameter("reminderType");
        int dosageCount = Integer.parseInt(request.getParameter("dosageCount"));

        // Cap dosageCount at 6
        if (dosageCount > 6) {
            dosageCount = 6;
        }

        String[] times = request.getParameterValues("time[]");

        // Limit times array to max 6
        if (times != null && times.length > 6) {
            String[] limitedTimes = new String[6];
            System.arraycopy(times, 0, limitedTimes, 0, 6);
            times = limitedTimes;
        }

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "login.html");
            return;
        }

        int userId = (int) session.getAttribute("userId");

        Connection conn = null;
        PreparedStatement pst = null;
        ResultSet rs = null;

        try {

            Class.forName("com.mysql.cj.jdbc.Driver");

            conn = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/healsync_db",
                    "root",
                    "Admin");

            // Insert into medicine_schedule
            String insertMedicine = "INSERT INTO medicine_schedule (user_id, medicine_name, start_date, end_date, dosage_count, dosage_instructions, reminder_type) VALUES (?, ?, ?, ?, ?, ?, ?)";

            pst = conn.prepareStatement(insertMedicine, Statement.RETURN_GENERATED_KEYS);

            pst.setInt(1, userId);
            pst.setString(2, medicineName);
            pst.setString(3, startDate);
            pst.setString(4, endDate);
            pst.setInt(5, dosageCount);
            pst.setString(6, (dosageInstructions == null || dosageInstructions.isEmpty()) ? null : dosageInstructions);
            pst.setString(7, reminderType);

            int rowsInserted = pst.executeUpdate();

            if (rowsInserted > 0) {

                rs = pst.getGeneratedKeys();

                int medicineId = -1;

                if (rs.next()) {
                    medicineId = rs.getInt(1);
                }

                // Insert times into medicine_times
                if (times != null && times.length > 0) {

                    String insertTime = "INSERT INTO medicine_times (medicine_id, med_time) VALUES (?, ?)";

                    pst = conn.prepareStatement(insertTime);

                    for (String time : times) {

                        if (time != null && !time.trim().isEmpty()) {

                            try {

                                pst.setInt(1, medicineId);
                                pst.setTime(2, Time.valueOf(time + ":00"));
                                pst.addBatch();

                            } catch (IllegalArgumentException e) {

                                System.out.println("Skipping invalid time format: " + time);

                            }
                        }
                    }

                    pst.executeBatch();
                }

                // Redirect to dashboard servlet
                response.sendRedirect(request.getContextPath() + "/dashboard?added=success");

            } else {

                response.sendRedirect(request.getContextPath() + "AddMedicine.html?error=insert");

            }

        } catch (Exception e) {

            e.printStackTrace();
            response.sendRedirect(request.getContextPath() + "AddMedicine.html?error=exception");

        } finally {

            try {
                if (rs != null)
                    rs.close();
            } catch (Exception ignored) {
            }

            try {
                if (pst != null)
                    pst.close();
            } catch (Exception ignored) {
            }

            try {
                if (conn != null)
                    conn.close();
            } catch (Exception ignored) {
            }
        }
    }
}
<%@ page import="java.sql.*, jakarta.servlet.http.*, jakarta.servlet.*" %>
<%
    // Check user session
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.html");
        return;
    }

    int userId = (int) session.getAttribute("userId");

    // Declare variables
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    String url = "jdbc:mysql://localhost:3306/healsync_db";
    String username = "root";
    String password = "Admin";
%>

<html>
<head>
    <title>My Medicines</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body class="my-medicines-page">
    <h2>My Medicine Schedule</h2>
    <table border="1">
        <tr>
            <th>Medicine Name</th>
            <th>Start Date</th>
            <th>End Date</th>
            <th>Dosage Count</th>
            <th>Dosage Instructions</th>
            <th>Reminder Type</th>
        </tr>
        <%
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(url, username, password);
                String sql = "SELECT * FROM medicine_schedule WHERE user_id = ?";
                pstmt = conn.prepareStatement(sql);
                pstmt.setInt(1, userId);
                rs = pstmt.executeQuery();

                while (rs.next()) {
        %>
                    <tr>
                        <td><%= rs.getString("medicine_name") %></td>
                        <td><%= rs.getDate("start_date") %></td>
                        <td><%= rs.getDate("end_date") %></td>
                        <td><%= rs.getInt("dosage_count") %></td>
                        <td><%= rs.getString("dosage_instructions") %></td>
                        <td><%= rs.getString("reminder_type") %></td>
                    </tr>
        <%
                }
            } catch (Exception e) {
                out.println("<tr><td colspan='6'>Error: " + e.getMessage() + "</td></tr>");
            } finally {
                try { if (rs != null) rs.close(); } catch (Exception e) {}
                try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
                try { if (conn != null) conn.close(); } catch (Exception e) {}
            }
        %>
    </table>
</body>
</html>

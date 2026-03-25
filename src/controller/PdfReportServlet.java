package controller;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.*;
import java.util.*;
import com.itextpdf.text.*;
import com.itextpdf.text.pdf.*;

public class PdfReportServlet extends HttpServlet {

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect(request.getContextPath() + "/login.html");
            return;
        }

        Integer userId = (Integer) session.getAttribute("userId");

        // Set response headers for PDF download
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=MedicinesReport.pdf");

        Document document = new Document();
        PdfWriter writer = null;

        try {

            writer = PdfWriter.getInstance(document, response.getOutputStream());
            document.open();

            // DB connection
            Class.forName("com.mysql.cj.jdbc.Driver");

            Connection conn = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/healsync_db",
                    "root",
                    "Admin");

            // Get user name
            String userName = "";

            PreparedStatement psUser = conn.prepareStatement(
                    "SELECT name AS username FROM users WHERE id = ?");

            psUser.setInt(1, userId);

            ResultSet rsUser = psUser.executeQuery();

            if (rsUser.next()) {
                userName = rsUser.getString("username");
            }

            rsUser.close();
            psUser.close();

            // Title
            Font titleFont = new Font(Font.FontFamily.HELVETICA, 18, Font.BOLD);

            Paragraph title = new Paragraph("Medicines Report", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);

            document.add(title);
            document.add(new Paragraph(" "));
            document.add(new Paragraph("User: " + userName));
            document.add(new Paragraph("Generated On: " + new java.util.Date().toString()));
            document.add(new Paragraph(" "));

            // Dose logs
            String query = "SELECT medicine_name, med_time, event_date, status " +
                    "FROM dose_logs WHERE user_id = ? ORDER BY event_date DESC, med_time ASC";

            PreparedStatement ps = conn.prepareStatement(query);

            ps.setInt(1, userId);

            ResultSet rs = ps.executeQuery();

            PdfPTable table = new PdfPTable(5);

            table.setWidthPercentage(100);
            table.setWidths(new int[]{3,2,2,2,2});

            addTableHeader(table,"Medicine Name");
            addTableHeader(table,"Date");
            addTableHeader(table,"Time");
            addTableHeader(table,"Dosage Count");
            addTableHeader(table,"Status");

            int rowCount = 0;

            while (rs.next()) {

                table.addCell(rs.getString("medicine_name"));
                table.addCell(rs.getDate("event_date").toString());
                table.addCell(rs.getString("med_time"));
                table.addCell("1");
                table.addCell(rs.getString("status"));

                rowCount++;
            }

            if (rowCount == 0) {
                document.add(new Paragraph("No dose logs available."));
            } else {
                document.add(table);
            }

            rs.close();
            ps.close();
            conn.close();

        } catch (Exception e) {

            e.printStackTrace();

            try {
                if (document.isOpen()) {
                    document.add(new Paragraph("Error generating report: " + e.getMessage()));
                }
            } catch (DocumentException de) {
                de.printStackTrace();
            }

        } finally {

            if (document.isOpen()) {
                document.close();
            }

            if (writer != null) {
                writer.close();
            }
        }
    }

    private void addTableHeader(PdfPTable table, String headerTitle) {

        Font headFont = new Font(Font.FontFamily.HELVETICA, 12, Font.BOLD);

        PdfPCell header = new PdfPCell();

        header.setBackgroundColor(BaseColor.LIGHT_GRAY);
        header.setHorizontalAlignment(Element.ALIGN_CENTER);
        header.setPhrase(new Phrase(headerTitle, headFont));

        table.addCell(header);
    }
}
package com.foodapp.donor.controller;

import com.foodapp.common.dto.ApiResponseDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.sql.DataSource;
import java.sql.*;
import java.util.*;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/donor")
public class DonorController {

    private static final Logger logger = LoggerFactory.getLogger(DonorController.class);
    
    @Autowired
    private DataSource dataSource;

    // Get all donations for a specific donor
    @GetMapping("/donations/{donorId}")
    public ResponseEntity<ApiResponseDTO<Map<String, Object>>> getDonorDonations(@PathVariable Long donorId) {
        try (Connection connection = dataSource.getConnection()) {
            // Verify user exists and is a donor
            if (!isValidDonor(connection, donorId)) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponseDTO.error(null, "Donor not found or invalid role."));
            }

            String sql = "SELECT d.*, u.first_name, u.last_name FROM donations d " +
                        "JOIN users u ON d.donor_id = u.id " +
                        "WHERE d.donor_id = ? " +
                        "ORDER BY CASE d.status " +
                        "WHEN 'current' THEN 1 " +
                        "WHEN 'donated' THEN 2 " +
                        "WHEN 'expired' THEN 3 " +
                        "ELSE 4 END, d.expiry_date ASC";

            try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
                pstmt.setLong(1, donorId);
                ResultSet rs = pstmt.executeQuery();

                List<Map<String, Object>> donations = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> donation = new HashMap<>();
                    donation.put("id", rs.getLong("id"));
                    donation.put("title", rs.getString("title"));
                    donation.put("description", rs.getString("description"));
                    donation.put("foodType", rs.getString("food_type"));
                    donation.put("quantity", rs.getInt("quantity"));
                    donation.put("unit", rs.getString("unit"));
                    donation.put("expiryDate", rs.getTimestamp("expiry_date"));
                    donation.put("pickupAddress", rs.getString("pickup_address"));
                    donation.put("pickupTime", rs.getTimestamp("pickup_time"));
                    donation.put("status", rs.getString("status"));
                    donation.put("volunteerId", rs.getObject("volunteer_id"));
                    donation.put("organizationId", rs.getObject("organization_id"));
                    donation.put("createdAt", rs.getTimestamp("created_at"));
                    donation.put("donorName", rs.getString("first_name") + " " + rs.getString("last_name"));
                    donations.add(donation);
                }

                Map<String, Object> response = new HashMap<>();
                response.put("donations", donations);
                response.put("donorId", donorId);

                return ResponseEntity.ok(ApiResponseDTO.success(response, "Donations retrieved successfully."));
            }
        } catch (SQLException e) {
            logger.error("Database error while fetching donations: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Database error: " + e.getMessage()));
        } catch (Exception e) {
            logger.error("Error while fetching donations: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Error: " + e.getMessage()));
        }
    }

    // Get all conversations for a donor
    @GetMapping("/conversations/{donorId}")
    public ResponseEntity<ApiResponseDTO<Map<String, Object>>> getDonorConversations(@PathVariable Long donorId) {
        try (Connection connection = dataSource.getConnection()) {
            // Verify user exists and is a donor
            if (!isValidDonor(connection, donorId)) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponseDTO.error(null, "Donor not found or invalid role."));
            }

            String sql = "SELECT c.*, u1.username as participant1_name, u2.username as participant2_name, " +
                        "u2.first_name as participant2_first, u2.last_name as participant2_last " +
                        "FROM conversations c " +
                        "JOIN users u1 ON c.participant1_id = u1.id " +
                        "JOIN users u2 ON c.participant2_id = u2.id " +
                        "WHERE c.participant1_id = ? " +
                        "ORDER BY c.last_message_at DESC";

            try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
                pstmt.setLong(1, donorId);
                ResultSet rs = pstmt.executeQuery();

                List<Map<String, Object>> conversations = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> conversation = new HashMap<>();
                    conversation.put("id", rs.getLong("id"));
                    conversation.put("participant2Id", rs.getLong("participant2_id"));
                    conversation.put("participant2Type", rs.getString("participant2_type"));
                    conversation.put("participant2Name", rs.getString("participant2_first") + " " + rs.getString("participant2_last"));
                    conversation.put("participant2Username", rs.getString("participant2_name"));
                    conversation.put("lastMessage", rs.getString("last_message"));
                    conversation.put("lastMessageAt", rs.getTimestamp("last_message_at"));
                    conversation.put("createdAt", rs.getTimestamp("created_at"));
                    conversations.add(conversation);
                }

                Map<String, Object> response = new HashMap<>();
                response.put("conversations", conversations);
                response.put("donorId", donorId);

                return ResponseEntity.ok(ApiResponseDTO.success(response, "Conversations retrieved successfully."));
            }
        } catch (SQLException e) {
            logger.error("Database error while fetching conversations: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Database error: " + e.getMessage()));
        } catch (Exception e) {
            logger.error("Error while fetching conversations: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Error: " + e.getMessage()));
        }
    }

    // Get messages for a specific conversation
    @GetMapping("/messages/{conversationId}")
    public ResponseEntity<ApiResponseDTO<Map<String, Object>>> getConversationMessages(@PathVariable Long conversationId) {
        try (Connection connection = dataSource.getConnection()) {
            // Verify conversation exists
            String checkSql = "SELECT c.*, u.role_id FROM conversations c " +
                             "JOIN users u ON c.participant1_id = u.id " +
                             "WHERE c.id = ?";
            try (PreparedStatement checkPstmt = connection.prepareStatement(checkSql)) {
                checkPstmt.setLong(1, conversationId);
                ResultSet checkRs = checkPstmt.executeQuery();
                if (!checkRs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(ApiResponseDTO.error(null, "Conversation not found."));
                }
            }

            String sql = "SELECT m.*, u.username, u.first_name, u.last_name " +
                        "FROM messages m " +
                        "JOIN users u ON m.sender_id = u.id " +
                        "WHERE m.conversation_id = ? " +
                        "ORDER BY m.created_at ASC";

            try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
                pstmt.setLong(1, conversationId);
                ResultSet rs = pstmt.executeQuery();

                List<Map<String, Object>> messages = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> message = new HashMap<>();
                    message.put("id", rs.getLong("id"));
                    message.put("senderId", rs.getLong("sender_id"));
                    message.put("senderName", rs.getString("first_name") + " " + rs.getString("last_name"));
                    message.put("senderUsername", rs.getString("username"));
                    message.put("messageText", rs.getString("message_text"));
                    message.put("isRead", rs.getBoolean("is_read"));
                    message.put("createdAt", rs.getTimestamp("created_at"));
                    messages.add(message);
                }

                Map<String, Object> response = new HashMap<>();
                response.put("messages", messages);
                response.put("conversationId", conversationId);

                return ResponseEntity.ok(ApiResponseDTO.success(response, "Messages retrieved successfully."));
            }
        } catch (SQLException e) {
            logger.error("Database error while fetching messages: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Database error: " + e.getMessage()));
        } catch (Exception e) {
            logger.error("Error while fetching messages: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Error: " + e.getMessage()));
        }
    }

    // Send a new message
    @PostMapping("/messages/send")
    public ResponseEntity<ApiResponseDTO<Map<String, Object>> sendMessage(@RequestBody Map<String, Object> request) {
        try (Connection connection = dataSource.getConnection()) {
            Long conversationId = Long.parseLong(request.get("conversationId").toString());
            Long senderId = Long.parseLong(request.get("senderId").toString());
            String messageText = request.get("messageText").toString();

            // Verify conversation exists and sender is a participant
            String checkSql = "SELECT * FROM conversations WHERE id = ? AND (participant1_id = ? OR participant2_id = ?)";
            try (PreparedStatement checkPstmt = connection.prepareStatement(checkSql)) {
                checkPstmt.setLong(1, conversationId);
                checkPstmt.setLong(2, senderId);
                checkPstmt.setLong(3, senderId);
                ResultSet checkRs = checkPstmt.executeQuery();
                if (!checkRs.next()) {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(ApiResponseDTO.error(null, "Conversation not found or invalid sender."));
                }
            }

            // Insert new message
            String insertSql = "INSERT INTO messages (conversation_id, sender_id, message_text, is_read) VALUES (?, ?, ?, FALSE)";
            try (PreparedStatement pstmt = connection.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                pstmt.setLong(1, conversationId);
                pstmt.setLong(2, senderId);
                pstmt.setString(3, messageText);
                pstmt.executeUpdate();

                // Update conversation's last message
                String updateSql = "UPDATE conversations SET last_message = ?, last_message_at = ? WHERE id = ?";
                try (PreparedStatement updatePstmt = connection.prepareStatement(updateSql)) {
                    updatePstmt.setString(1, messageText);
                    updatePstmt.setTimestamp(2, Timestamp.valueOf(LocalDateTime.now()));
                    updatePstmt.setLong(3, conversationId);
                    updatePstmt.executeUpdate();
                }

                Map<String, Object> response = new HashMap<>();
                response.put("message", "Message sent successfully.");
                response.put("conversationId", conversationId);

                return ResponseEntity.ok(ApiResponseDTO.success(response, "Message sent successfully."));
            }
        } catch (SQLException e) {
            logger.error("Database error while sending message: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Database error: " + e.getMessage()));
        } catch (Exception e) {
            logger.error("Error while sending message: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Error: " + e.getMessage()));
        }
    }

    // Helper method to verify if user is a valid donor
    private boolean isValidDonor(Connection connection, Long donorId) throws SQLException {
        String sql = "SELECT u.id FROM users u " +
                    "JOIN roles r ON u.role_id = r.id " +
                    "WHERE u.id = ? AND r.name = 'donor' AND u.is_active = TRUE";
        try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
            pstmt.setLong(1, donorId);
            ResultSet rs = pstmt.executeQuery();
            return rs.next();
        }
    }

    // Get donor profile information
    @GetMapping("/profile/{donorId}")
    public ResponseEntity<ApiResponseDTO<Map<String, Object>>> getDonorProfile(@PathVariable Long donorId) {
        try (Connection connection = dataSource.getConnection()) {
            String sql = "SELECT u.id, u.username, u.email, u.first_name, u.last_name, u.phone, " +
                        "r.name as role_name, u.created_at " +
                        "FROM users u " +
                        "JOIN roles r ON u.role_id = r.id " +
                        "WHERE u.id = ? AND r.name = 'donor'";

            try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
                pstmt.setLong(1, donorId);
                ResultSet rs = pstmt.executeQuery();

                if (rs.next()) {
                    Map<String, Object> profile = new HashMap<>();
                    profile.put("id", rs.getLong("id"));
                    profile.put("username", rs.getString("username"));
                    profile.put("email", rs.getString("email"));
                    profile.put("firstName", rs.getString("first_name"));
                    profile.put("lastName", rs.getString("last_name"));
                    profile.put("phone", rs.getString("phone"));
                    profile.put("roleName", rs.getString("role_name"));
                    profile.put("createdAt", rs.getTimestamp("created_at"));

                    // Get donation statistics
                    String statsSql = "SELECT COUNT(*) as total, " +
                                     "SUM(CASE WHEN status = 'current' THEN 1 ELSE 0 END) as current, " +
                                     "SUM(CASE WHEN status = 'donated' THEN 1 ELSE 0 END) as donated, " +
                                     "SUM(CASE WHEN status = 'expired' THEN 1 ELSE 0 END) as expired " +
                                     "FROM donations WHERE donor_id = ?";
                    try (PreparedStatement statsPstmt = connection.prepareStatement(statsSql)) {
                        statsPstmt.setLong(1, donorId);
                        ResultSet statsRs = statsPstmt.executeQuery();
                        if (statsRs.next()) {
                            Map<String, Object> stats = new HashMap<>();
                            stats.put("total", statsRs.getInt("total"));
                            stats.put("current", statsRs.getInt("current"));
                            stats.put("donated", statsRs.getInt("donated"));
                            stats.put("expired", statsRs.getInt("expired"));
                            profile.put("donationStats", stats);
                        }
                    }

                    return ResponseEntity.ok(ApiResponseDTO.success(profile, "Profile retrieved successfully."));
                } else {
                    return ResponseEntity.status(HttpStatus.NOT_FOUND)
                            .body(ApiResponseDTO.error(null, "Donor profile not found."));
                }
            }
        } catch (SQLException e) {
            logger.error("Database error while fetching profile: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Database error: " + e.getMessage()));
        } catch (Exception e) {
            logger.error("Error while fetching profile: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponseDTO.error(null, "Error: " + e.getMessage()));
        }
    }
}
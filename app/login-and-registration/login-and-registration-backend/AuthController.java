package com.foodapp.auth.controller;

import com.foodapp.common.dto.ApiResponseDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.dao.DataAccessException;

import javax.sql.DataSource;
import java.sql.*;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Authentication Controller for Food App
 * Handles user registration, login, and session management
 * Supports role-based access control
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private DataSource dataSource;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * User Registration Endpoint
     * Registers a new user with specified role
     */
    @PostMapping("/register")
    public ResponseEntity<ApiResponseDTO<Map<String, Object>>> register(@RequestBody RegistrationRequest request) {
        try (Connection conn = dataSource.getConnection()) {
            // Validate input
            if (request.getUsername() == null || request.getEmail() == null || 
                request.getPassword() == null || request.getFirstName() == null || 
                request.getLastName() == null || request.getRoleId() == null) {
                return ResponseEntity.badRequest()
                    .body(ApiResponseDTO.error("All required fields must be provided"));
            }

            // Check if user already exists
            if (userExists(conn, request.getUsername(), request.getEmail())) {
                return ResponseEntity.badRequest()
                    .body(ApiResponseDTO.error("User with this username or email already exists"));
            }

            // Validate role exists
            if (!roleExists(conn, request.getRoleId())) {
                return ResponseEntity.badRequest()
                    .body(ApiResponseDTO.error("Invalid role selected"));
            }

            // Hash password
            String hashedPassword = passwordEncoder.encode(request.getPassword());

            // Insert new user
            String insertUserSql = "INSERT INTO users (username, email, password_hash, first_name, last_name, phone, role_id, email_verified) " +
                                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING id";
            
            try (PreparedStatement stmt = conn.prepareStatement(insertUserSql)) {
                stmt.setString(1, request.getUsername());
                stmt.setString(2, request.getEmail());
                stmt.setString(3, hashedPassword);
                stmt.setString(4, request.getFirstName());
                stmt.setString(5, request.getLastName());
                stmt.setString(6, request.getPhone());
                stmt.setInt(7, request.getRoleId());
                stmt.setBoolean(8, false); // Email not verified by default

                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        int userId = rs.getInt("id");
                        Map<String, Object> userData = getUserData(conn, userId);
                        
                        return ResponseEntity.ok()
                            .body(ApiResponseDTO.success("User registered successfully", userData));
                    }
                }
            }

            return ResponseEntity.badRequest()
                .body(ApiResponseDTO.error("Registration failed"));

        } catch (DataAccessException e) {
            return ResponseEntity.internalServerError()
                .body(ApiResponseDTO.error("Database error occurred", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(ApiResponseDTO.error("Registration failed", e.getMessage()));
        }
    }

    /**
     * User Login Endpoint
     * Authenticates user and creates session
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponseDTO<Map<String, Object>>> login(@RequestBody LoginRequest request) {
        try (Connection conn = dataSource.getConnection()) {
            // Validate input
            if (request.getUsername() == null || request.getPassword() == null) {
                return ResponseEntity.badRequest()
                    .body(ApiResponseDTO.error("Username and password are required"));
            }

            // Find user by username or email
            String findUserSql = "SELECT u.*, r.name as role_name FROM users u " +
                               "JOIN roles r ON u.role_id = r.id " +
                               "WHERE (u.username = ? OR u.email = ?) AND u.is_active = true";
            
            User user = null;
            try (PreparedStatement stmt = conn.prepareStatement(findUserSql)) {
                stmt.setString(1, request.getUsername());
                stmt.setString(2, request.getUsername());
                
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        user = new User(rs);
                    }
                }
            }

            if (user == null) {
                return ResponseEntity.badRequest()
                    .body(ApiResponseDTO.error("Invalid credentials"));
            }

            // Verify password
            if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
                return ResponseEntity.badRequest()
                    .body(ApiResponseDTO.error("Invalid credentials"));
            }

            // Create session
            String sessionToken = UUID.randomUUID().toString();
            LocalDateTime expiresAt = LocalDateTime.now().plusDays(7); // 7-day session

            String insertSessionSql = "INSERT INTO user_sessions (user_id, session_token, expires_at) VALUES (?, ?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(insertSessionSql)) {
                stmt.setInt(1, user.getId());
                stmt.setString(2, sessionToken);
                stmt.setTimestamp(3, Timestamp.valueOf(expiresAt));
                stmt.executeUpdate();
            }

            // Update last login
            String updateLoginSql = "UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(updateLoginSql)) {
                stmt.setInt(1, user.getId());
                stmt.executeUpdate();
            }

            // Prepare response data
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("user", user.toMap());
            responseData.put("sessionToken", sessionToken);
            responseData.put("expiresAt", expiresAt);

            return ResponseEntity.ok()
                .body(ApiResponseDTO.success("Login successful", responseData));

        } catch (DataAccessException e) {
            return ResponseEntity.internalServerError()
                .body(ApiResponseDTO.error("Database error occurred", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(ApiResponseDTO.error("Login failed", e.getMessage()));
        }
    }

    /**
     * Get Available Roles
     * Returns list of all available roles for registration
     */
    @GetMapping("/roles")
    public ResponseEntity<ApiResponseDTO<Map<String, Object>>> getRoles() {
        try (Connection conn = dataSource.getConnection()) {
            String sql = "SELECT id, name, description FROM roles ORDER BY id";
            Map<Integer, Map<String, Object>> roles = new HashMap<>();
            
            try (PreparedStatement stmt = conn.prepareStatement(sql);
                 ResultSet rs = stmt.executeQuery()) {
                
                while (rs.next()) {
                    Map<String, Object> role = new HashMap<>();
                    role.put("id", rs.getInt("id"));
                    role.put("name", rs.getString("name"));
                    role.put("description", rs.getString("description"));
                    roles.put(rs.getInt("id"), role);
                }
            }

            return ResponseEntity.ok()
                .body(ApiResponseDTO.success("Roles retrieved successfully", roles));

        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(ApiResponseDTO.error("Failed to retrieve roles", e.getMessage()));
        }
    }

    /**
     * Logout Endpoint
     * Invalidates user session
     */
    @PostMapping("/logout")
    public ResponseEntity<ApiResponseDTO<String>> logout(@RequestHeader("Authorization") String sessionToken) {
        try (Connection conn = dataSource.getConnection()) {
            if (sessionToken == null || !sessionToken.startsWith("Bearer ")) {
                return ResponseEntity.badRequest()
                    .body(ApiResponseDTO.error("Invalid session token"));
            }

            String token = sessionToken.substring(7); // Remove "Bearer " prefix
            String sql = "DELETE FROM user_sessions WHERE session_token = ?";
            
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, token);
                int rowsAffected = stmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    return ResponseEntity.ok()
                        .body(ApiResponseDTO.success("Logout successful"));
                } else {
                    return ResponseEntity.badRequest()
                        .body(ApiResponseDTO.error("Invalid session token"));
                }
            }

        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(ApiResponseDTO.error("Logout failed", e.getMessage()));
        }
    }

    // Helper methods
    private boolean userExists(Connection conn, String username, String email) throws SQLException {
        String sql = "SELECT COUNT(*) FROM users WHERE username = ? OR email = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setString(1, username);
            stmt.setString(2, email);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    private boolean roleExists(Connection conn, int roleId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM roles WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, roleId);
            try (ResultSet rs = stmt.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        }
    }

    private Map<String, Object> getUserData(Connection conn, int userId) throws SQLException {
        String sql = "SELECT u.*, r.name as role_name FROM users u " +
                    "JOIN roles r ON u.role_id = r.id WHERE u.id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    User user = new User(rs);
                    return user.toMap();
                }
            }
        }
        return null;
    }

    // Request DTOs
    public static class RegistrationRequest {
        private String username;
        private String email;
        private String password;
        private String firstName;
        private String lastName;
        private String phone;
        private Integer roleId;

        // Getters and Setters
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
        public String getFirstName() { return firstName; }
        public void setFirstName(String firstName) { this.firstName = firstName; }
        public String getLastName() { return lastName; }
        public void setLastName(String lastName) { this.lastName = lastName; }
        public String getPhone() { return phone; }
        public void setPhone(String phone) { this.phone = phone; }
        public Integer getRoleId() { return roleId; }
        public void setRoleId(Integer roleId) { this.roleId = roleId; }
    }

    public static class LoginRequest {
        private String username;
        private String password;

        // Getters and Setters
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    // User model
    public static class User {
        private int id;
        private String username;
        private String email;
        private String passwordHash;
        private String firstName;
        private String lastName;
        private String phone;
        private int roleId;
        private String roleName;
        private boolean isActive;
        private boolean emailVerified;
        private LocalDateTime lastLogin;

        public User(ResultSet rs) throws SQLException {
            this.id = rs.getInt("id");
            this.username = rs.getString("username");
            this.email = rs.getString("email");
            this.passwordHash = rs.getString("password_hash");
            this.firstName = rs.getString("first_name");
            this.lastName = rs.getString("last_name");
            this.phone = rs.getString("phone");
            this.roleId = rs.getInt("role_id");
            this.roleName = rs.getString("role_name");
            this.isActive = rs.getBoolean("is_active");
            this.emailVerified = rs.getBoolean("email_verified");
            Timestamp lastLoginTs = rs.getTimestamp("last_login");
            if (lastLoginTs != null) {
                this.lastLogin = lastLoginTs.toLocalDateTime();
            }
        }

        public Map<String, Object> toMap() {
            Map<String, Object> map = new HashMap<>();
            map.put("id", id);
            map.put("username", username);
            map.put("email", email);
            map.put("firstName", firstName);
            map.put("lastName", lastName);
            map.put("phone", phone);
            map.put("roleId", roleId);
            map.put("roleName", roleName);
            map.put("isActive", isActive);
            map.put("emailVerified", emailVerified);
            map.put("lastLogin", lastLogin);
            return map;
        }

        // Getters
        public int getId() { return id; }
        public String getUsername() { return username; }
        public String getEmail() { return email; }
        public String getPasswordHash() { return passwordHash; }
        public String getFirstName() { return firstName; }
        public String getLastName() { return lastName; }
        public String getPhone() { return phone; }
        public int getRoleId() { return roleId; }
        public String getRoleName() { return roleName; }
        public boolean isActive() { return isActive; }
        public boolean isEmailVerified() { return emailVerified; }
        public LocalDateTime getLastLogin() { return lastLogin; }
    }
}
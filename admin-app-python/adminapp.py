import webview
from flask import Flask, jsonify, request
import pymysql
from datetime import datetime, timedelta
import json
import threading
import hashlib
import bcrypt

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'root',
    'db': 'food_app',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

def get_db_connection():
    return pymysql.connect(**DB_CONFIG)

def hash_password(password):
    """Hash password using bcrypt (same as backend)"""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(10)).decode('utf-8')

def verify_password(password, hashed):
    """Verify password against bcrypt hash"""
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

# HTML Template
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Food Donation Admin</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --primary: #6366f1;
            --primary-dark: #4f46e5;
            --secondary: #10b981;
            --danger: #ef4444;
            --dark: #1e293b;
            --darker: #0f172a;
            --light: #f8fafc;
            --glass: rgba(255, 255, 255, 0.1);
            --glass-border: rgba(255, 255, 255, 0.1);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
        }

        body {
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            color: var(--light);
            min-height: 100vh;
            line-height: 1.6;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 1rem;
        }

        /* Navbar */
        .navbar {
            background: rgba(15, 23, 42, 0.8);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            border-bottom: 1px solid var(--glass-border);
            padding: 1rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: sticky;
            top: 0;
            z-index: 1000;
        }

        .logo {
            font-size: 1.5rem;
            font-weight: 700;
            background: linear-gradient(90deg, var(--primary), var(--secondary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        /* Tabs */
        .tabs {
            display: flex;
            gap: 1rem;
            margin: 1rem 0;
            border-bottom: 1px solid var(--glass-border);
        }

        .tab {
            padding: 0.75rem 1.5rem;
            cursor: pointer;
            border-radius: 0.5rem 0.5rem 0 0;
            transition: all 0.3s ease;
            font-weight: 500;
            color: var(--light);
            opacity: 0.7;
        }

        .tab.active {
            background: var(--glass);
            border: 1px solid var(--glass-border);
            border-bottom: none;
            opacity: 1;
            transform: translateY(1px);
        }

        .tab:hover {
            opacity: 1;
            background: var(--glass);
        }

        /* Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: var(--glass);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            border: 1px solid var(--glass-border);
            border-radius: 1rem;
            padding: 1.5rem;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 10px 20px rgba(0, 0, 0, 0.2);
        }

        .stat-card h3 {
            font-size: 0.9rem;
            color: #94a3b8;
            margin-bottom: 0.5rem;
        }

        .stat-card .value {
            font-size: 2rem;
            font-weight: 700;
            background: linear-gradient(90deg, var(--primary), var(--secondary));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        /* Charts */
        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .chart-container {
            background: var(--glass);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            border: 1px solid var(--glass-border);
            border-radius: 1rem;
            padding: 1.5rem;
            transition: all 0.3s ease;
        }

        .chart-container:hover {
            transform: translateY(-3px);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
        }

        .chart-container h3 {
            margin-bottom: 1rem;
            color: #e2e8f0;
            font-size: 1.1rem;
            font-weight: 600;
        }

        .chart-wrapper {
            position: relative;
            height: 300px;
            width: 100%;
        }

        /* Tables */
        .table-container {
            background: var(--glass);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            border: 1px solid var(--glass-border);
            border-radius: 1rem;
            overflow: hidden;
            margin-bottom: 2rem;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th, td {
            padding: 1rem;
            text-align: left;
            border-bottom: 1px solid var(--glass-border);
        }

        th {
            background: rgba(15, 23, 42, 0.5);
            font-weight: 600;
            color: #94a3b8;
        }

        tr:hover {
            background: rgba(255, 255, 255, 0.05);
        }

        /* Badges */
        .badge {
            padding: 0.25rem 0.75rem;
            border-radius: 9999px;
            font-size: 0.75rem;
            font-weight: 600;
            display: inline-block;
        }

        /* Flex utilities */
        .flex {
            display: flex;
        }
        
        .justify-between {
            justify-content: space-between;
        }
        
        .items-center {
            align-items: center;
        }
        
        .gap-2 {
            gap: 0.5rem;
        }
        
        .gap-4 {
            gap: 1rem;
        }

        /* Grid utilities */
        .grid {
            display: grid;
        }
        
        .grid-cols-1 {
            grid-template-columns: repeat(1, minmax(0, 1fr));
        }
        
        .grid-cols-2 {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }
        
        .grid-cols-3 {
            grid-template-columns: repeat(3, minmax(0, 1fr));
        }

        /* Text utilities */
        .text-sm {
            font-size: 0.875rem;
        }
        
        .text-gray-400 {
            color: #9ca3af;
        }
        
        .text-2xl {
            font-size: 1.5rem;
        }
        
        .font-bold {
            font-weight: 700;
        }
        
        .mb-6 {
            margin-bottom: 1.5rem;
        }

        /* Buttons */
        .btn {
            padding: 0.5rem 1rem;
            border: none;
            border-radius: 0.5rem;
            cursor: pointer;
            font-weight: 500;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }

        .btn-sm {
            padding: 0.25rem 0.75rem;
            font-size: 0.875rem;
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
            transform: translateY(-2px);
        }

        .btn-danger {
            background: var(--danger);
            color: white;
        }

        .btn-danger:hover {
            opacity: 0.9;
            transform: translateY(-2px);
        }

        .btn-edit {
            background: #f59e0b;
            color: white;
        }

        .btn-edit:hover {
            opacity: 0.9;
            transform: translateY(-2px);
        }

        /* Modal */
        .modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.7);
            backdrop-filter: blur(5px);
            z-index: 1000;
            justify-content: center;
            align-items: center;
            opacity: 0;
            transition: opacity 0.3s ease;
        }

        .modal.show {
            display: flex;
            opacity: 1;
        }

        .modal-content {
            background: #1e293b;
            border-radius: 1rem;
            width: 90%;
            max-width: 600px;
            max-height: 90vh;
            overflow-y: auto;
            padding: 2rem;
            position: relative;
            border: 1px solid var(--glass-border);
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
            transform: translateY(20px);
            transition: transform 0.3s ease;
        }

        .modal.show .modal-content {
            transform: translateY(0);
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid var(--glass-border);
        }

        .modal-title {
            font-size: 1.5rem;
            font-weight: 600;
            color: #e2e8f0;
        }

        .close-btn {
            background: none;
            border: none;
            color: #94a3b8;
            font-size: 1.5rem;
            cursor: pointer;
            transition: color 0.2s;
        }

        .close-btn:hover {
            color: #e2e8f0;
        }

        .form-group {
            margin-bottom: 1.5rem;
        }

        .form-group label {
            display: block;
            margin-bottom: 0.5rem;
            color: #94a3b8;
            font-weight: 500;
        }

        .form-control {
            width: 100%;
            padding: 0.75rem 1rem;
            background: rgba(15, 23, 42, 0.5);
            border: 1px solid var(--glass-border);
            border-radius: 0.5rem;
            color: #e2e8f0;
            font-size: 1rem;
            transition: all 0.3s ease;
        }

        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.3);
        }

        .form-actions {
            display: flex;
            justify-content: flex-end;
            gap: 1rem;
            margin-top: 2rem;
            padding-top: 1.5rem;
            border-top: 1px solid var(--glass-border);
        }

        /* Animations */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .fade-in {
            animation: fadeIn 0.5s ease forwards;
        }

        /* Responsive */
        @media (max-width: 1024px) {
            .charts-grid {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 768px) {
            .stats-grid {
                grid-template-columns: 1fr 1fr;
            }
            
            .table-container {
                overflow-x: auto;
            }
            
            table {
                min-width: 800px;
            }
            
            .grid-cols-2, .grid-cols-3 {
                grid-template-columns: 1fr;
            }
        }

        @media (max-width: 576px) {
            .stats-grid {
                grid-template-columns: 1fr;
            }
            
            .modal-content {
                width: 95%;
                padding: 1.5rem 1rem;
            }
            
            .tabs {
                flex-direction: column;
            }
            
            .tab {
                border-radius: 0.5rem;
                margin-bottom: 0.5rem;
            }
            
            .tab.active {
                border: 1px solid var(--glass-border);
                transform: none;
            }
        }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="logo">Food Donation Admin</div>
        <div id="current-time" class="text-sm text-gray-400"></div>
    </div>

    <div class="container">
        <div class="tabs">
            <div class="tab active" onclick="showTab('analytics')">Analytics</div>
            <div class="tab" onclick="showTab('users')">Users</div>
            <div class="tab" onclick="showTab('donations')">Donations</div>
        </div>

        <!-- Analytics Tab -->
        <div id="analytics" class="tab-content">
            <h2 class="text-2xl font-bold mb-6">Dashboard Overview</h2>
            
            <div class="stats-grid">
                <div class="stat-card fade-in" style="animation-delay: 0.1s">
                    <h3>Total Users</h3>
                    <div class="value counter" id="total-users">0</div>
                </div>
                <div class="stat-card fade-in" style="animation-delay: 0.2s">
                    <h3>Total Donations</h3>
                    <div class="value counter" id="total-donations">0</div>
                </div>
                <div class="stat-card fade-in" style="animation-delay: 0.3s">
                    <h3>Active Volunteers</h3>
                    <div class="value counter" id="active-volunteers">0</div>
                </div>
                <div class="stat-card fade-in" style="animation-delay: 0.4s">
                    <h3>Completion Rate</h3>
                    <div class="value"><span id="completion-rate">0</span>%</div>
                </div>
            </div>

            <div class="charts-grid">
                <div class="chart-container fade-in" style="animation-delay: 0.2s">
                    <h3>Daily Donations (Last 30 Days)</h3>
                    <div class="chart-wrapper">
                        <canvas id="donationsChart"></canvas>
                    </div>
                </div>
                <div class="chart-container fade-in" style="animation-delay: 0.3s">
                    <h3>Donation Status Distribution</h3>
                    <div class="chart-wrapper">
                        <canvas id="statusChart"></canvas>
                    </div>
                </div>
                <div class="chart-container fade-in" style="animation-delay: 0.4s">
                    <h3>Top Organizations by Donations Claimed</h3>
                    <div class="chart-wrapper">
                        <canvas id="orgsChart"></canvas>
                    </div>
                </div>
                <div class="chart-container fade-in" style="animation-delay: 0.5s">
                    <h3>Top Volunteers by Completed Deliveries</h3>
                    <div class="chart-wrapper">
                        <canvas id="volunteersChart"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <!-- Users Tab -->
        <div id="users" class="tab-content" style="display: none;">
            <div class="flex justify-between items-center mb-6">
                <h2 class="text-2xl font-bold">User Management</h2>
                <button class="btn btn-primary" onclick="openUserModal()">
                    <span>+ Add User</span>
                </button>
            </div>
            
            <div class="table-container">
                <table id="users-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Name</th>
                            <th>Email</th>
                            <th>Phone</th>
                            <th>Role</th>
                            <th>Created At</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="users-table-body">
                        <!-- Filled by JavaScript -->
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Donations Tab -->
        <div id="donations" class="tab-content" style="display: none;">
            <div class="flex justify-between items-center mb-6">
                <h2 class="text-2xl font-bold">Donation Management</h2>
                <div class="flex gap-2">
                    <select id="status-filter" class="form-control" onchange="loadDonations()" style="max-width: 200px;">
                        <option value="">All Status</option>
                        <option value="available">Available</option>
                        <option value="claimed">Claimed</option>
                        <option value="in_transit">In Transit</option>
                        <option value="completed">Completed</option>
                        <option value="cancelled">Cancelled</option>
                    </select>
                </div>
            </div>
            
            <div class="table-container">
                <table id="donations-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Title</th>
                            <th>Quantity</th>
                            <th>Status</th>
                            <th>Donor</th>
                            <th>Volunteer</th>
                            <th>Organization</th>
                            <th>Expiry</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="donations-table-body">
                        <!-- Filled by JavaScript -->
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- User Modal -->
    <div id="user-modal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3 class="modal-title" id="user-modal-title">Add New User</h3>
                <button class="close-btn" onclick="closeModal('user-modal')">&times;</button>
            </div>
            <form id="user-form" onsubmit="saveUser(event)">
                <input type="hidden" id="user-id">
                <div class="form-group">
                    <label for="first-name">First Name</label>
                    <input type="text" id="first-name" class="form-control" required>
                </div>
                <div class="form-group">
                    <label for="last-name">Last Name</label>
                    <input type="text" id="last-name" class="form-control" required>
                </div>
                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" class="form-control" required>
                </div>
                <div class="form-group">
                    <label for="phone">Phone</label>
                    <input type="text" id="phone" class="form-control">
                </div>
                <div class="form-group">
                    <label for="role">Role</label>
                    <select id="role" class="form-control" required>
                        <option value="donor">Donor</option>
                        <option value="volunteer">Volunteer</option>
                        <option value="organization">Organization</option>
                        <option value="admin">Admin</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" class="form-control" placeholder="Leave blank to keep current">
                </div>
                <div class="form-actions">
                    <button type="button" class="btn btn-danger" onclick="deleteUser()" id="delete-btn" style="display: none;">Delete</button>
                    <button type="button" class="btn" onclick="closeModal('user-modal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Donation Modal -->
    <div id="donation-modal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3 class="modal-title" id="donation-modal-title">Edit Donation</h3>
                <button class="close-btn" onclick="closeModal('donation-modal')">&times;</button>
            </div>
            <form id="donation-form" onsubmit="saveDonation(event)">
                <input type="hidden" id="donation-id">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="form-group">
                        <label for="title">Title</label>
                        <input type="text" id="title" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="donation-type">Type</label>
                        <select id="donation-type" class="form-control" required>
                            <option value="food">Food</option>
                            <option value="clothes">Clothes</option>
                            <option value="other">Other</option>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="description">Description</label>
                    <textarea id="description" class="form-control" rows="3"></textarea>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div class="form-group">
                        <label for="quantity">Quantity</label>
                        <input type="number" id="quantity" class="form-control" min="1" required>
                    </div>
                    <div class="form-group">
                        <label for="unit">Unit</label>
                        <select id="unit" class="form-control" required>
                            <option value="kg">kg</option>
                            <option value="g">g</option>
                            <option value="pieces">Pieces</option>
                            <option value="liters">Liters</option>
                            <option value="boxes">Boxes</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="status">Status</label>
                        <select id="status" class="form-control" required>
                            <option value="available">Available</option>
                            <option value="claimed">Claimed</option>
                            <option value="in_transit">In Transit</option>
                            <option value="completed">Completed</option>
                            <option value="cancelled">Cancelled</option>
                        </select>
                    </div>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="form-group">
                        <label for="expiry-date">Expiry Date</label>
                        <input type="datetime-local" id="expiry-date" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label for="pickup-time">Pickup Time</label>
                        <input type="datetime-local" id="pickup-time" class="form-control">
                    </div>
                </div>
                <div class="form-group">
                    <label for="pickup-address">Pickup Address</label>
                    <textarea id="pickup-address" class="form-control" rows="2" required></textarea>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div class="form-group">
                        <label for="donor">Donor</label>
                        <select id="donor" class="form-control" required>
                            <!-- Filled by JavaScript -->
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="volunteer">Volunteer</label>
                        <select id="volunteer" class="form-control">
                            <option value="">None</option>
                            <!-- Filled by JavaScript -->
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="organization">Organization</label>
                    <select id="organization" class="form-control">
                        <option value="">None</option>
                        <!-- Filled by JavaScript -->
                    </select>
                </div>
                <div class="form-actions">
                    <button type="button" class="btn btn-danger" onclick="deleteDonation()" id="delete-donation-btn" style="display: none;">Delete</button>
                    <button type="button" class="btn" onclick="closeModal('donation-modal')">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        // Global variables
        let charts = {};
        let users = [];
        let donations = [];
        let donors = [];
        let volunteers = [];
        let organizations = [];

        // Initialize the application
        document.addEventListener('DOMContentLoaded', function() {
            updateClock();
            setInterval(updateClock, 60000);
            
            // Load initial data
            loadAnalytics();
            loadUsers();
            loadDonations();
            loadUserSelects();
            
            // Set up event listeners
            setupEventListeners();
        });

        // Update clock
        function updateClock() {
            const now = new Date();
            document.getElementById('current-time').textContent = now.toLocaleString('en-US', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        // Tab navigation
        function showTab(tabName) {
            // Hide all tab contents
            document.querySelectorAll('.tab-content').forEach(tab => {
                tab.style.display = 'none';
            });
            
            // Remove active class from all tabs
            document.querySelectorAll('.tab').forEach(tab => {
                tab.classList.remove('active');
            });
            
            // Show selected tab content
            document.getElementById(tabName).style.display = 'block';
            
            // Add active class to clicked tab
            event.currentTarget.classList.add('active');
            
            // Refresh data if needed
            if (tabName === 'analytics') {
                loadAnalytics();
            } else if (tabName === 'users') {
                loadUsers();
            } else if (tabName === 'donations') {
                loadDonations();
            }
        }

        // Modal functions
        function openModal(modalId) {
            const modal = document.getElementById(modalId);
            modal.style.display = 'flex';
            setTimeout(() => {
                modal.classList.add('show');
            }, 10);
        }

        function closeModal(modalId) {
            const modal = document.getElementById(modalId);
            modal.classList.remove('show');
            setTimeout(() => {
                modal.style.display = 'none';
            }, 300);
        }

        // User Management
        function openUserModal(user = null) {
            const modal = document.getElementById('user-modal');
            const form = document.getElementById('user-form');
            const title = document.getElementById('user-modal-title');
            const deleteBtn = document.getElementById('delete-btn');
            
            if (user) {
                // Edit mode
                title.textContent = 'Edit User';
                document.getElementById('user-id').value = user.id;
                document.getElementById('first-name').value = user.first_name || '';
                document.getElementById('last-name').value = user.last_name || '';
                document.getElementById('email').value = user.email || '';
                document.getElementById('phone').value = user.phone || '';
                document.getElementById('role').value = user.role || 'donor';
                document.getElementById('password').placeholder = 'Leave blank to keep current';
                document.getElementById('password').required = false;
                deleteBtn.style.display = 'inline-block';
                deleteBtn.onclick = () => deleteUser(user.id);
            } else {
                // Add mode
                title.textContent = 'Add New User';
                form.reset();
                document.getElementById('user-id').value = '';
                document.getElementById('password').placeholder = 'Enter password';
                document.getElementById('password').required = true;
                deleteBtn.style.display = 'none';
            }
            
            openModal('user-modal');
        }

        function saveUser(event) {
            event.preventDefault();
            
            const userId = document.getElementById('user-id').value;
            const userData = {
                first_name: document.getElementById('first-name').value,
                last_name: document.getElementById('last-name').value,
                email: document.getElementById('email').value,
                phone: document.getElementById('phone').value,
                role: document.getElementById('role').value
            };
            
            const password = document.getElementById('password').value;
            if (password) {
                userData.password = password;
            } else if (!userId) {
                alert('Password is required for new users');
                return;
            }
            
            const url = userId ? `/api/users/${userId}` : '/api/users';
            const method = userId ? 'PUT' : 'POST';
            
            fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(userData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    closeModal('user-modal');
                    loadUsers();
                    if (!userId) loadAnalytics(); // Refresh stats if new user
                } else {
                    alert(data.message || 'Error saving user');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error saving user');
            });
        }

        function deleteUser(userId = null) {
            if (!userId) userId = document.getElementById('user-id').value;
            if (!userId) return;
            
            if (confirm('Are you sure you want to delete this user?')) {
                fetch(`/api/users/${userId}`, {
                    method: 'DELETE'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        closeModal('user-modal');
                        loadUsers();
                        loadAnalytics(); // Refresh stats
                    } else {
                        alert(data.message || 'Error deleting user');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error deleting user');
                });
            }
        }

        // Donation Management
        function openDonationModal(donation = null) {
            const modal = document.getElementById('donation-modal');
            const form = document.getElementById('donation-form');
            const title = document.getElementById('donation-modal-title');
            const deleteBtn = document.getElementById('delete-donation-btn');
            
            if (donation) {
                // Edit mode
                title.textContent = 'Edit Donation';
                document.getElementById('donation-id').value = donation.id;
                document.getElementById('title').value = donation.title || '';
                document.getElementById('description').value = donation.description || '';
                document.getElementById('donation-type').value = donation.donation_type || 'food';
                document.getElementById('quantity').value = donation.quantity || 1;
                document.getElementById('unit').value = donation.unit || 'kg';
                document.getElementById('expiry-date').value = formatDateTimeForInput(donation.expiry_date);
                document.getElementById('pickup-time').value = formatDateTimeForInput(donation.pickup_time);
                document.getElementById('pickup-address').value = donation.pickup_address || '';
                document.getElementById('status').value = donation.status || 'available';
                document.getElementById('donor').value = donation.donor_id || '';
                document.getElementById('volunteer').value = donation.volunteer_id || '';
                document.getElementById('organization').value = donation.organization_id || '';
                deleteBtn.style.display = 'inline-block';
                deleteBtn.onclick = () => deleteDonation(donation.id);
            } else {
                // Add mode
                title.textContent = 'Add New Donation';
                form.reset();
                document.getElementById('donation-id').value = '';
                document.getElementById('donation-type').value = 'food';
                document.getElementById('quantity').value = '1';
                document.getElementById('unit').value = 'kg';
                document.getElementById('status').value = 'available';
                deleteBtn.style.display = 'none';
            }
            
            openModal('donation-modal');
        }

        function formatDateTimeForInput(dateTimeStr) {
            if (!dateTimeStr) return '';
            const date = new Date(dateTimeStr);
            return date.toISOString().slice(0, 16); // YYYY-MM-DDTHH:MM
        }

        function saveDonation(event) {
            event.preventDefault();
            
            const donationId = document.getElementById('donation-id').value;
            const donationData = {
                title: document.getElementById('title').value,
                description: document.getElementById('description').value,
                donation_type: document.getElementById('donation-type').value,
                quantity: parseFloat(document.getElementById('quantity').value),
                unit: document.getElementById('unit').value,
                expiry_date: document.getElementById('expiry-date').value,
                pickup_time: document.getElementById('pickup-time').value || null,
                pickup_address: document.getElementById('pickup-address').value,
                status: document.getElementById('status').value,
                donor_id: parseInt(document.getElementById('donor').value) || null,
                volunteer_id: parseInt(document.getElementById('volunteer').value) || null,
                organization_id: parseInt(document.getElementById('organization').value) || null
            };
            
            const url = donationId ? `/api/donations/${donationId}` : '/api/donations';
            const method = donationId ? 'PUT' : 'POST';
            
            fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(donationData)
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    closeModal('donation-modal');
                    loadDonations();
                    if (!donationId) loadAnalytics(); // Refresh stats if new donation
                } else {
                    alert(data.message || 'Error saving donation');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error saving donation');
            });
        }

        function deleteDonation(donationId = null) {
            if (!donationId) donationId = document.getElementById('donation-id').value;
            if (!donationId) return;
            
            if (confirm('Are you sure you want to delete this donation?')) {
                fetch(`/api/donations/${donationId}`, {
                    method: 'DELETE'
                })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        closeModal('donation-modal');
                        loadDonations();
                        loadAnalytics(); // Refresh stats
                    } else {
                        alert(data.message || 'Error deleting donation');
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Error deleting donation');
                });
            }
        }

        // Data loading functions
        function loadAnalytics() {
            // Load stats
            fetch('/api/analytics')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        updateStats(data.data);
                        renderCharts(data.data);
                    }
                })
                .catch(error => {
                    console.error('Error loading analytics:', error);
                });
        }

        function loadUsers() {
            fetch('/api/users')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        users = data.data;
                        renderUsersTable(users);
                    }
                })
                .catch(error => {
                    console.error('Error loading users:', error);
                });
        }

        function loadDonations() {
            const status = document.getElementById('status-filter').value;
            let url = '/api/donations';
            if (status) {
                url += `?status=${status}`;
            }
            
            fetch(url)
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        donations = data.data;
                        renderDonationsTable(donations);
                    }
                })
                .catch(error => {
                    console.error('Error loading donations:', error);
                });
        }

        function loadUserSelects() {
            // Load donors, volunteers, and organizations for selects
            Promise.all([
                fetch('/api/users?role=donor').then(res => res.json()),
                fetch('/api/users?role=volunteer').then(res => res.json()),
                fetch('/api/users?role=organization').then(res => res.json())
            ])
            .then(([donorsData, volunteersData, orgsData]) => {
                if (donorsData.success) {
                    donors = donorsData.data;
                    updateSelect('donor', donors);
                }
                if (volunteersData.success) {
                    volunteers = volunteersData.data;
                    updateSelect('volunteer', volunteers);
                }
                if (orgsData.success) {
                    organizations = orgsData.data;
                    updateSelect('organization', organizations);
                }
            })
            .catch(error => {
                console.error('Error loading user selects:', error);
            });

            function updateSelect(selectId, items) {
                const select = document.getElementById(selectId);
                select.innerHTML = '<option value="">None</option>';
                items.forEach(item => {
                    const option = document.createElement('option');
                    option.value = item.id;
                    option.textContent = `${item.first_name} ${item.last_name}`;
                    select.appendChild(option);
                });
            }
        }

        function updateStats(data) {
            // Update stat cards with animation
            const totalUsers = Object.values(data.user_counts || {}).reduce((a, b) => a + b, 0);
            animateCounter('total-users', totalUsers);
            animateCounter('total-donations', data.total_donations || 0);
            animateCounter('active-volunteers', data.active_volunteers || 0);
            animateCounter('completion-rate', data.completion_rate || 0);
        }

        function animateCounter(elementId, targetValue) {
            const element = document.getElementById(elementId);
            if (!element) return;
            
            const startValue = parseInt(element.textContent) || 0;
            const duration = 1000;
            const startTime = performance.now();
            
            function updateCounter(currentTime) {
                const elapsed = currentTime - startTime;
                const progress = Math.min(elapsed / duration, 1);
                const currentValue = Math.floor(startValue + (targetValue - startValue) * progress);
                element.textContent = currentValue;
                
                if (progress < 1) {
                    requestAnimationFrame(updateCounter);
                }
            }
            
            requestAnimationFrame(updateCounter);
        }

        function renderCharts(data) {
            // Destroy existing charts
            Object.values(charts).forEach(chart => chart.destroy());
            charts = {};
            
            // Daily donations line chart
            const donationsCtx = document.getElementById('donationsChart');
            if (donationsCtx) {
                charts.donations = new Chart(donationsCtx.getContext('2d'), {
                    type: 'line',
                    data: {
                        labels: (data.daily_donations || []).map(d => new Date(d.date).toLocaleDateString()),
                        datasets: [{
                            label: 'Donations',
                            data: (data.daily_donations || []).map(d => d.count),
                            borderColor: '#6366f1',
                            backgroundColor: 'rgba(99, 102, 241, 0.1)',
                            tension: 0.4,
                            fill: true
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                display: false
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                grid: {
                                    color: 'rgba(255, 255, 255, 0.1)'
                                },
                                ticks: {
                                    color: '#94a3b8'
                                }
                            },
                            x: {
                                grid: {
                                    color: 'rgba(255, 255, 255, 0.1)'
                                },
                                ticks: {
                                    color: '#94a3b8'
                                }
                            }
                        }
                    }
                });
            }
            
            // Status distribution donut chart
            const statusCtx = document.getElementById('statusChart');
            if (statusCtx) {
                charts.status = new Chart(statusCtx.getContext('2d'), {
                    type: 'doughnut',
                    data: {
                        labels: (data.status_distribution || []).map(d => d.status),
                        datasets: [{
                            data: (data.status_distribution || []).map(d => d.count),
                            backgroundColor: [
                                '#6366f1',
                                '#10b981',
                                '#f59e0b',
                                '#ef4444',
                                '#8b5cf6'
                            ]
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom',
                                labels: {
                                    color: '#94a3b8'
                                }
                            }
                        }
                    }
                });
            }
            
            // Top organizations bar chart
            const orgsCtx = document.getElementById('orgsChart');
            if (orgsCtx) {
                charts.orgs = new Chart(orgsCtx.getContext('2d'), {
                    type: 'bar',
                    data: {
                        labels: (data.top_organizations || []).map(o => o.name),
                        datasets: [{
                            label: 'Donations Claimed',
                            data: (data.top_organizations || []).map(o => o.donation_count),
                            backgroundColor: '#10b981'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                display: false
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                grid: {
                                    color: 'rgba(255, 255, 255, 0.1)'
                                },
                                ticks: {
                                    color: '#94a3b8'
                                }
                            },
                            x: {
                                grid: {
                                    color: 'rgba(255, 255, 255, 0.1)'
                                },
                                ticks: {
                                    color: '#94a3b8'
                                }
                            }
                        }
                    }
                });
            }
            
            // Top volunteers bar chart
            const volunteersCtx = document.getElementById('volunteersChart');
            if (volunteersCtx) {
                charts.volunteers = new Chart(volunteersCtx.getContext('2d'), {
                    type: 'bar',
                    data: {
                        labels: (data.top_volunteers || []).map(v => v.name),
                        datasets: [{
                            label: 'Completed Deliveries',
                            data: (data.top_volunteers || []).map(v => v.completed_deliveries),
                            backgroundColor: '#f59e0b'
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                display: false
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                grid: {
                                    color: 'rgba(255, 255, 255, 0.1)'
                                },
                                ticks: {
                                    color: '#94a3b8'
                                }
                            },
                            x: {
                                grid: {
                                    color: 'rgba(255, 255, 255, 0.1)'
                                },
                                ticks: {
                                    color: '#94a3b8'
                                }
                            }
                        }
                    }
                });
            }
        }

        function renderUsersTable(users) {
            const tbody = document.getElementById('users-table-body');
            if (!tbody) return;
            
            tbody.innerHTML = '';
            
            users.forEach(user => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${user.id}</td>
                    <td>${user.first_name} ${user.last_name}</td>
                    <td>${user.email}</td>
                    <td>${user.phone || '-'}</td>
                    <td><span class="badge" style="background: #6366f1">${user.role}</span></td>
                    <td>${new Date(user.created_at).toLocaleDateString()}</td>
                    <td>
                        <button class="btn btn-edit btn-sm" onclick="openUserModal(${JSON.stringify(user).replace(/"/g, '&quot;')})">Edit</button>
                    </td>
                `;
                tbody.appendChild(row);
            });
        }

        function renderDonationsTable(donations) {
            const tbody = document.getElementById('donations-table-body');
            if (!tbody) return;
            
            tbody.innerHTML = '';
            
            donations.forEach(donation => {
                const row = document.createElement('tr');
                const statusColor = getStatusColor(donation.status);
                row.innerHTML = `
                    <td>${donation.id}</td>
                    <td>${donation.title}</td>
                    <td>${donation.quantity} ${donation.unit}</td>
                    <td><span class="badge" style="background: ${statusColor}">${donation.status}</span></td>
                    <td>${donation.donor_name || '-'}</td>
                    <td>${donation.volunteer_name || '-'}</td>
                    <td>${donation.org_name || '-'}</td>
                    <td>${new Date(donation.expiry_date).toLocaleDateString()}</td>
                    <td>
                        <button class="btn btn-edit btn-sm" onclick="openDonationModal(${JSON.stringify(donation).replace(/"/g, '&quot;')})">Edit</button>
                    </td>
                `;
                tbody.appendChild(row);
            });
        }

        function getStatusColor(status) {
            const colors = {
                'available': '#10b981',
                'claimed': '#6366f1',
                'in_transit': '#f59e0b',
                'completed': '#22c55e',
                'cancelled': '#ef4444'
            };
            return colors[status] || '#6b7280';
        }

        function setupEventListeners() {
            // Close modals when clicking outside
            document.querySelectorAll('.modal').forEach(modal => {
                modal.addEventListener('click', function(e) {
                    if (e.target === modal) {
                        closeModal(modal.id);
                    }
                });
            });
            
            // Prevent form submission on enter in modals
            document.querySelectorAll('.modal form').forEach(form => {
                form.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && e.target.tagName !== 'TEXTAREA') {
                        e.preventDefault();
                    }
                });
            });
        }
    </script>
</body>
</html>
"""

# Flask API Routes
@app.route('/api/analytics')
def get_analytics():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Get user counts by role
            cursor.execute("SELECT role, COUNT(*) as count FROM users WHERE role IN ('donor', 'volunteer', 'organization') GROUP BY role")
            role_counts = {row['role']: row['count'] for row in cursor.fetchall()}
            
            # Get donation stats
            cursor.execute("SELECT COUNT(*) as total FROM donations")
            total_donations = cursor.fetchone()['total']
            
            cursor.execute("SELECT COUNT(DISTINCT volunteer_id) as active_volunteers FROM volunteers WHERE status = 'accepted'")
            result = cursor.fetchone()
            active_volunteers = result['active_volunteers'] if result else 0
            
            cursor.execute("SELECT COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed, COUNT(*) as total FROM donations")
            completion_stats = cursor.fetchone()
            completion_rate = round((completion_stats['completed'] / completion_stats['total']) * 100) if completion_stats['total'] > 0 else 0
            
            # Get daily donations for last 30 days
            cursor.execute("SELECT DATE(created_at) as date, COUNT(*) as count FROM donations WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY) GROUP BY DATE(created_at) ORDER BY date")
            daily_donations = cursor.fetchall()
            
            # Get donation status distribution
            cursor.execute("SELECT status, COUNT(*) as count FROM donations GROUP BY status")
            status_distribution = cursor.fetchall()
            
            # Get top organizations
            cursor.execute("""
                SELECT u.id, CONCAT(u.first_name, ' ', u.last_name) as name, 
                       COUNT(d.id) as donation_count 
                FROM users u 
                LEFT JOIN donations d ON u.id = d.organization_id 
                WHERE u.role = 'organization' 
                GROUP BY u.id 
                ORDER BY donation_count DESC 
                LIMIT 5
            """)
            top_organizations = cursor.fetchall()
            
            # Get top volunteers
            cursor.execute("""
                SELECT u.id, CONCAT(u.first_name, ' ', u.last_name) as name, 
                       COUNT(v.id) as completed_deliveries 
                FROM users u 
                LEFT JOIN volunteers v ON u.id = v.volunteer_id 
                WHERE u.role = 'volunteer' AND v.status = 'completed' 
                GROUP BY u.id 
                ORDER BY completed_deliveries DESC 
                LIMIT 5
            """)
            top_volunteers = cursor.fetchall()
            
            return jsonify({
                'success': True,
                'data': {
                    'user_counts': role_counts,
                    'total_donations': total_donations,
                    'active_volunteers': active_volunteers,
                    'completion_rate': completion_rate,
                    'daily_donations': daily_donations,
                    'status_distribution': status_distribution,
                    'top_organizations': top_organizations,
                    'top_volunteers': top_volunteers
                }
            })
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        conn.close()

@app.route('/api/users', methods=['GET', 'POST'])
def handle_users():
    if request.method == 'GET':
        role = request.args.get('role')
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                if role:
                    sql = "SELECT * FROM users WHERE role = %s ORDER BY created_at DESC"
                    cursor.execute(sql, (role,))
                else:
                    sql = "SELECT * FROM users ORDER BY created_at DESC"
                    cursor.execute(sql)
                users = cursor.fetchall()
                return jsonify({'success': True, 'data': users})
        except Exception as e:
            return jsonify({'success': False, 'message': str(e)}), 500
        finally:
            conn.close()
    elif request.method == 'POST':
        data = request.get_json()
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                password_hash = hash_password(data.get('password')) if data.get('password') else None
                if not password_hash:
                    return jsonify({'success': False, 'message': 'Password is required'}), 400
                    
                cursor.execute("""
                    INSERT INTO users 
                    (username, email, password_hash, first_name, last_name, phone, role, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, (
                    data.get('email').split('@')[0],  # Simple username from email
                    data.get('email'),
                    password_hash,
                    data.get('first_name'),
                    data.get('last_name'),
                    data.get('phone'),
                    data.get('role', 'donor')
                ))
                user_id = cursor.lastrowid
                conn.commit()
                return jsonify({'success': True, 'id': user_id})
        except Exception as e:
            conn.rollback()
            return jsonify({'success': False, 'message': str(e)}), 500
        finally:
            conn.close()

@app.route('/api/users/<int:user_id>', methods=['PUT', 'DELETE'])
def handle_user(user_id):
    if request.method == 'PUT':
        data = request.get_json()
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                update_fields = []
                values = []
                
                if 'first_name' in data:
                    update_fields.append("first_name = %s")
                    values.append(data.get('first_name'))
                if 'last_name' in data:
                    update_fields.append("last_name = %s")
                    values.append(data.get('last_name'))
                if 'email' in data:
                    update_fields.append("email = %s")
                    values.append(data.get('email'))
                if 'phone' in data:
                    update_fields.append("phone = %s")
                    values.append(data.get('phone'))
                if 'role' in data:
                    update_fields.append("role = %s")
                    values.append(data.get('role'))
                if 'password' in data and data.get('password'):
                    update_fields.append("password_hash = %s")
                    values.append(hash_password(data.get('password')))
                
                update_fields.append("updated_at = NOW()")
                values.append(user_id)
                
                sql = f"UPDATE users SET {', '.join(update_fields)} WHERE id = %s"
                cursor.execute(sql, tuple(values))
                conn.commit()
                return jsonify({'success': True})
        except Exception as e:
            conn.rollback()
            return jsonify({'success': False, 'message': str(e)}), 500
        finally:
            conn.close()
    elif request.method == 'DELETE':
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM users WHERE id = %s", (user_id,))
                conn.commit()
                return jsonify({'success': True})
        except Exception as e:
            conn.rollback()
            return jsonify({'success': False, 'message': str(e)}), 500
        finally:
            conn.close()

@app.route('/api/donations', methods=['GET', 'POST'])
def handle_donations():
    if request.method == 'GET':
        status = request.args.get('status')
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                sql = """
                    SELECT d.*, 
                           CONCAT(du.first_name, ' ', du.last_name) as donor_name,
                           CONCAT(vu.first_name, ' ', vu.last_name) as volunteer_name,
                           CONCAT(ou.first_name, ' ', ou.last_name) as org_name
                    FROM donations d
                    LEFT JOIN users du ON d.donor_id = du.id
                    LEFT JOIN users vu ON d.volunteer_id = vu.id
                    LEFT JOIN users ou ON d.organization_id = ou.id
                """
                if status:
                    sql += " WHERE d.status = %s"
                    cursor.execute(sql, (status,))
                else:
                    cursor.execute(sql)
                donations = cursor.fetchall()
                return jsonify({'success': True, 'data': donations})
        except Exception as e:
            return jsonify({'success': False, 'message': str(e)}), 500
        finally:
            conn.close()
    elif request.method == 'POST':
        data = request.get_json()
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO donations 
                    (donor_id, title, description, donation_type, quantity, unit, 
                     expiry_date, pickup_address, pickup_time, status, 
                     volunteer_id, organization_id, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, (
                    data.get('donor_id'),
                    data.get('title'),
                    data.get('description'),
                    data.get('donation_type', 'food'),
                    data.get('quantity', 1),
                    data.get('unit', 'kg'),
                    data.get('expiry_date'),
                    data.get('pickup_address'),
                    data.get('pickup_time'),
                    data.get('status', 'available'),
                    data.get('volunteer_id'),
                    data.get('organization_id')
                ))
                donation_id = cursor.lastrowid
                conn.commit()
                return jsonify({'success': True, 'id': donation_id})
        except Exception as e:
            conn.rollback()
            return jsonify({'success': False, 'message': str(e)}), 500
        finally:
            conn.close()

@app.route('/api/donations/<int:donation_id>', methods=['PUT', 'DELETE'])
def handle_donation(donation_id):
    if request.method == 'PUT':
        data = request.get_json()
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE donations 
                    SET title = %s,
                        description = %s,
                        donation_type = %s,
                        quantity = %s,
                        unit = %s,
                        expiry_date = %s,
                        pickup_address = %s,
                        pickup_time = %s,
                        status = %s,
                        donor_id = %s,
                        volunteer_id = %s,
                        organization_id = %s,
                        updated_at = NOW()
                    WHERE id = %s
                """, (
                    data.get('title'),
                    data.get('description'),
                    data.get('donation_type'),
                    data.get('quantity'),
                    data.get('unit'),
                    data.get('expiry_date'),
                    data.get('pickup_address'),
                    data.get('pickup_time'),
                    data.get('status'),
                    data.get('donor_id'),
                    data.get('volunteer_id'),
                    data.get('organization_id'),
                    donation_id
                ))
                conn.commit()
                return jsonify({'success': True})
        except Exception as e:
            conn.rollback()
            return jsonify({'success': False, 'message': str(e)}), 500
        finally:
            conn.close()
    elif request.method == 'DELETE':
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute("DELETE FROM donations WHERE id = %s", (donation_id,))
                conn.commit()
                return jsonify({'success': True})
        except Exception as e:
            conn.rollback()
            return jsonify({'success': False, 'message': str(e)}), 500
        finally:
            conn.close()

@app.route('/')
def index():
    return HTML_TEMPLATE

def run_flask():
    app.run(host='127.0.0.1', port=3000, debug=False, use_reloader=False)

if __name__ == '__main__':
    # Start Flask in a separate thread
    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True
    flask_thread.start()
    
    # Create and start the webview window
    window = webview.create_window(
        'Food Donation Admin',
        'http://127.0.0.1:3000',
        width=1200,
        height=800,
        min_size=(800, 600),
        text_select=True
    )
    
    webview.start(debug=False)
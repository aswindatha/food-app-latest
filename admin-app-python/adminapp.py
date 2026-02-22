import webview
from flask import Flask, jsonify, request, send_file, abort
import pymysql
from datetime import datetime, timedelta
import json
import threading
import hashlib
import bcrypt
import os
from pathlib import Path

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

# Document upload directory - relative to project root
UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'backend', 'src', 'assets')

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
    <title>Food Donation Admin - Organization Approval</title>
    <style>
        :root {
            --primary: #6366f1;
            --primary-dark: #4f46e5;
            --secondary: #10b981;
            --danger: #ef4444;
            --warning: #f59e0b;
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
            flex-wrap: wrap;
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

        /* Organization Cards Grid */
        .org-cards-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(450px, 1fr));
            gap: 1.5rem;
            margin-top: 1.5rem;
        }

        .org-card {
            background: var(--glass);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            border: 1px solid var(--glass-border);
            border-radius: 1rem;
            overflow: hidden;
            transition: all 0.3s ease;
            animation: slideIn 0.5s ease forwards;
        }

        .org-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 30px rgba(0, 0, 0, 0.3);
            border-color: var(--primary);
        }

        .org-card-header {
            background: linear-gradient(135deg, var(--primary-dark), var(--primary));
            padding: 1.5rem;
            position: relative;
        }

        .org-card-header h3 {
            font-size: 1.5rem;
            font-weight: 600;
            margin-bottom: 0.5rem;
        }

        .org-card-header .org-username {
            font-size: 0.9rem;
            opacity: 0.9;
            font-family: monospace;
        }

        .org-badge {
            position: absolute;
            top: 1rem;
            right: 1rem;
            background: rgba(255, 255, 255, 0.2);
            padding: 0.25rem 1rem;
            border-radius: 9999px;
            font-size: 0.8rem;
            font-weight: 600;
            backdrop-filter: blur(5px);
        }

        .org-card-body {
            padding: 1.5rem;
        }

        .org-detail-item {
            margin-bottom: 1rem;
            padding: 0.75rem;
            background: rgba(0, 0, 0, 0.2);
            border-radius: 0.5rem;
            border-left: 3px solid var(--primary);
        }

        .org-detail-item .label {
            font-size: 0.8rem;
            color: #94a3b8;
            margin-bottom: 0.25rem;
        }

        .org-detail-item .value {
            font-size: 1rem;
            font-weight: 500;
            word-break: break-word;
        }

        .document-preview {
            margin-top: 1rem;
            padding: 1rem;
            background: rgba(0, 0, 0, 0.3);
            border-radius: 0.5rem;
        }

        .document-preview .label {
            font-size: 0.8rem;
            color: #94a3b8;
            margin-bottom: 0.5rem;
        }

        .document-content {
            max-height: 150px;
            overflow-y: auto;
            padding: 0.75rem;
            background: rgba(15, 23, 42, 0.5);
            border-radius: 0.5rem;
            font-family: monospace;
            font-size: 0.9rem;
            white-space: pre-wrap;
            word-break: break-word;
            margin-bottom: 1rem;
        }

        .document-actions {
            display: flex;
            gap: 0.5rem;
            flex-wrap: wrap;
        }

        .document-link {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            background: var(--primary);
            color: white;
            text-decoration: none;
            border-radius: 0.5rem;
            font-size: 0.9rem;
            transition: all 0.2s ease;
            border: none;
            cursor: pointer;
        }

        .document-link:hover {
            background: var(--primary-dark);
            transform: translateY(-2px);
        }

        .document-link.view-pdf {
            background: var(--secondary);
        }

        .document-link.view-pdf:hover {
            background: #0d9488;
        }

        .coordinates {
            display: flex;
            gap: 1rem;
            margin-top: 0.5rem;
        }

        .coordinate {
            flex: 1;
            padding: 0.5rem;
            background: rgba(99, 102, 241, 0.1);
            border-radius: 0.5rem;
            text-align: center;
            font-size: 0.9rem;
        }

        .org-card-footer {
            padding: 1.5rem;
            background: rgba(0, 0, 0, 0.2);
            display: flex;
            gap: 1rem;
            justify-content: flex-end;
            border-top: 1px solid var(--glass-border);
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

        .badge-pending {
            background: var(--warning);
            color: var(--dark);
        }

        .badge-approved {
            background: var(--secondary);
            color: white;
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
            font-size: 0.9rem;
        }

        .btn-sm {
            padding: 0.25rem 0.75rem;
            font-size: 0.8rem;
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
            transform: translateY(-2px);
        }

        .btn-success {
            background: var(--secondary);
            color: white;
        }

        .btn-success:hover {
            opacity: 0.9;
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

        .btn-warning {
            background: var(--warning);
            color: white;
        }

        .btn-warning:hover {
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
            max-width: 800px;
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

        /* Document Viewer Modal */
        .document-viewer {
            width: 100%;
            height: 70vh;
            border: none;
            border-radius: 0.5rem;
            background: white;
        }

        .pdf-viewer {
            width: 100%;
            height: 70vh;
            border: none;
            border-radius: 0.5rem;
        }

        .modal-actions {
            display: flex;
            justify-content: flex-end;
            gap: 1rem;
            margin-top: 1rem;
        }

        /* Empty state */
        .empty-state {
            text-align: center;
            padding: 3rem;
            background: var(--glass);
            border-radius: 1rem;
            color: #94a3b8;
        }

        .empty-state i {
            font-size: 3rem;
            margin-bottom: 1rem;
            opacity: 0.5;
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

        .mb-4 {
            margin-bottom: 1rem;
        }

        .mb-6 {
            margin-bottom: 1.5rem;
        }

        .mt-4 {
            margin-top: 1rem;
        }

        /* Text utilities */
        .text-sm {
            font-size: 0.875rem;
        }
        
        .text-lg {
            font-size: 1.125rem;
        }
        
        .text-xl {
            font-size: 1.25rem;
        }
        
        .text-2xl {
            font-size: 1.5rem;
        }
        
        .font-bold {
            font-weight: 700;
        }
        
        .text-gray-400 {
            color: #9ca3af;
        }
        
        .text-center {
            text-align: center;
        }

        /* Animations */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        @keyframes slideIn {
            from { opacity: 0; transform: translateX(-20px); }
            to { opacity: 1; transform: translateX(0); }
        }

        .fade-in {
            animation: fadeIn 0.5s ease forwards;
        }

        /* Responsive */
        @media (max-width: 768px) {
            .org-cards-grid {
                grid-template-columns: 1fr;
            }
            
            .table-container {
                overflow-x: auto;
            }
            
            table {
                min-width: 800px;
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

            .coordinates {
                flex-direction: column;
                gap: 0.5rem;
            }

            .document-actions {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="logo">Food Donation Admin - Organization Approval</div>
        <div id="current-time" class="text-sm text-gray-400"></div>
    </div>

    <div class="container">
        <div class="tabs">
            <div class="tab active" onclick="showTab('approvals')">Organization Approvals</div>
            <div class="tab" onclick="showTab('users')">Users</div>
            <div class="tab" onclick="showTab('donations')">Donations</div>
        </div>

        <!-- Organization Approvals Tab -->
        <div id="approvals" class="tab-content">
            <div class="flex justify-between items-center mb-6">
                <h2 class="text-2xl font-bold">Pending Organization Approvals</h2>
                <div class="flex gap-2">
                    <span class="badge badge-pending" id="pending-count">0 Pending</span>
                </div>
            </div>
            
            <div id="pending-orgs-container">
                <!-- Organizations will be loaded here -->
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
                            <th>Username</th>
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

    <!-- Document Viewer Modal -->
    <div id="document-modal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h3 class="modal-title" id="document-modal-title">Document Viewer</h3>
                <button class="close-btn" onclick="closeModal('document-modal')">&times;</button>
            </div>
            <div id="document-viewer-container">
                <!-- Document will be loaded here -->
            </div>
            <div class="modal-actions">
                <a id="download-document-link" href="#" target="_blank" class="btn btn-primary">
                    <span>⬇️</span> Download
                </a>
                <button class="btn" onclick="closeModal('document-modal')">Close</button>
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

    <style>
        /* Modal styles */
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
            max-width: 800px;
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
        
        @media (min-width: 768px) {
            .md\\:grid-cols-2 {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
            
            .md\\:grid-cols-3 {
                grid-template-columns: repeat(3, minmax(0, 1fr));
            }
        }

        /* PDF Viewer */
        .pdf-viewer {
            width: 100%;
            height: 60vh;
            border: none;
            border-radius: 0.5rem;
        }

        .document-info {
            padding: 1rem;
            background: rgba(0, 0, 0, 0.2);
            border-radius: 0.5rem;
            margin-bottom: 1rem;
        }
    </style>

    <script>
        // Global variables
        let users = [];
        let donations = [];
        let pendingOrgs = [];
        let donors = [];
        let volunteers = [];
        let organizations = [];

        // Initialize the application
        document.addEventListener('DOMContentLoaded', function() {
            updateClock();
            setInterval(updateClock, 60000);
            
            // Load initial data
            loadPendingOrganizations();
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
            if (tabName === 'approvals') {
                loadPendingOrganizations();
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

        // Document viewing function
        function viewDocument(documentPath) {
            if (!documentPath) {
                alert('No document available');
                return;
            }

            const modal = document.getElementById('document-modal');
            const container = document.getElementById('document-viewer-container');
            const title = document.getElementById('document-modal-title');
            const downloadLink = document.getElementById('download-document-link');
            
            title.textContent = 'Document Viewer - ' + documentPath.split('/').pop();
            
            // Check file type
            const fileExt = documentPath.split('.').pop().toLowerCase();
            const isPDF = fileExt === 'pdf';
            
            // Create document viewer
            let viewerHtml = '';
            
            if (isPDF) {
                // For PDF files, use native browser PDF viewer
                viewerHtml = `
                    <div class="document-info">
                        <strong>File:</strong> ${documentPath.split('/').pop()}
                    </div>
                    <iframe 
                        src="/api/documents/${documentPath}" 
                        class="pdf-viewer"
                        frameborder="0">
                    </iframe>
                `;
            } else {
                // For other files, show info and download option
                viewerHtml = `
                    <div class="document-info">
                        <strong>File:</strong> ${documentPath.split('/').pop()}<br>
                        <strong>Type:</strong> ${fileExt.toUpperCase()} file
                    </div>
                    <div class="text-center" style="padding: 3rem; background: rgba(0,0,0,0.2); border-radius: 0.5rem;">
                        <div style="font-size: 3rem; margin-bottom: 1rem;">📄</div>
                        <p>This file type cannot be previewed directly.</p>
                        <p>Please use the download button below to view the document.</p>
                    </div>
                `;
            }
            
            container.innerHTML = viewerHtml;
            
            // Set download link
            downloadLink.href = `/api/documents/${documentPath}`;
            
            openModal('document-modal');
        }

        // Load pending organizations (username starts with #)
        function loadPendingOrganizations() {
            fetch('/api/organizations/pending')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        pendingOrgs = data.data;
                        renderPendingOrganizations(pendingOrgs);
                        document.getElementById('pending-count').textContent = `${pendingOrgs.length} Pending`;
                    }
                })
                .catch(error => {
                    console.error('Error loading pending organizations:', error);
                    showEmptyState('Error loading organizations');
                });
        }

        // Render pending organizations as cards
        function renderPendingOrganizations(orgs) {
            const container = document.getElementById('pending-orgs-container');
            
            if (!container) return;
            
            if (orgs.length === 0) {
                container.innerHTML = `
                    <div class="empty-state fade-in">
                        <div style="font-size: 3rem; margin-bottom: 1rem;">📋</div>
                        <h3 class="text-lg font-bold mb-2">No Pending Approvals</h3>
                        <p class="text-gray-400">All organization registrations have been processed.</p>
                    </div>
                `;
                return;
            }
            
            let html = '<div class="org-cards-grid">';
            
            orgs.forEach(org => {
                const createdDate = new Date(org.created_at).toLocaleDateString('en-US', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                });
                
                const documentName = org.document_path ? org.document_path.split('/').pop() : 'No document';
                const fileExt = org.document_path ? org.document_path.split('.').pop().toLowerCase() : '';
                const isPDF = fileExt === 'pdf';
                
                html += `
                    <div class="org-card fade-in" data-org-id="${org.id}">
                        <div class="org-card-header">
                            <h3>${org.first_name} ${org.last_name}</h3>
                            <div class="org-username">${org.username}</div>
                            <div class="org-badge">Pending Approval</div>
                        </div>
                        <div class="org-card-body">
                            <div class="org-detail-item">
                                <div class="label">Email</div>
                                <div class="value">${org.email || 'Not provided'}</div>
                            </div>
                            <div class="org-detail-item">
                                <div class="label">Phone</div>
                                <div class="value">${org.phone || 'Not provided'}</div>
                            </div>
                            <div class="org-detail-item">
                                <div class="label">Address</div>
                                <div class="value">${org.address || 'Not provided'}</div>
                            </div>
                            ${org.latitude && org.longitude ? `
                            <div class="org-detail-item">
                                <div class="label">Location Coordinates</div>
                                <div class="coordinates">
                                    <div class="coordinate">Lat: ${org.latitude}</div>
                                    <div class="coordinate">Long: ${org.longitude}</div>
                                </div>
                            </div>
                            ` : ''}
                            <div class="org-detail-item">
                                <div class="label">Registration Date</div>
                                <div class="value">${createdDate}</div>
                            </div>
                            ${org.document_path ? `
                            <div class="document-preview">
                                <div class="label">Submitted Document</div>
                                <div class="document-content">
                                    ${documentName}
                                </div>
                                <div class="document-actions">
                                    <button onclick="viewDocument('${encodeURIComponent(org.document_path)}')" class="document-link ${isPDF ? 'view-pdf' : ''}">
                                        <span>${isPDF ? '📄' : '📁'}</span> ${isPDF ? 'View PDF' : 'View Document'}
                                    </button>
                                    <a href="/api/documents/${encodeURIComponent(org.document_path)}" target="_blank" class="document-link" download>
                                        <span>⬇️</span> Download
                                    </a>
                                </div>
                            </div>
                            ` : ''}
                        </div>
                        <div class="org-card-footer">
                            <button class="btn btn-success" onclick="approveOrganization(${org.id}, '${org.username}')">
                                <span>✓</span> Approve
                            </button>
                            <button class="btn btn-danger" onclick="rejectOrganization(${org.id})">
                                <span>✗</span> Reject
                            </button>
                        </div>
                    </div>
                `;
            });
            
            html += '</div>';
            container.innerHTML = html;
        }

        // Approve organization (remove # from username)
        function approveOrganization(orgId, username) {
            if (!confirm('Are you sure you want to approve this organization? They will be able to access the system.')) {
                return;
            }
            
            fetch(`/api/organizations/${orgId}/approve`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Remove the approved org from the list with animation
                    const orgCard = document.querySelector(`.org-card[data-org-id="${orgId}"]`);
                    if (orgCard) {
                        orgCard.style.opacity = '0';
                        orgCard.style.transform = 'scale(0.8)';
                        setTimeout(() => {
                            loadPendingOrganizations(); // Reload the list
                            loadUsers(); // Refresh users list to show the new approved org
                            loadUserSelects(); // Refresh selects
                        }, 300);
                    }
                } else {
                    alert(data.message || 'Error approving organization');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error approving organization');
            });
        }

        // Reject organization (delete from database)
        function rejectOrganization(orgId) {
            if (!confirm('Are you sure you want to reject this organization? This will permanently delete their registration.')) {
                return;
            }
            
            fetch(`/api/organizations/${orgId}/reject`, {
                method: 'DELETE'
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Remove the rejected org from the list with animation
                    const orgCard = document.querySelector(`.org-card[data-org-id="${orgId}"]`);
                    if (orgCard) {
                        orgCard.style.opacity = '0';
                        orgCard.style.transform = 'scale(0.8)';
                        setTimeout(() => {
                            loadPendingOrganizations(); // Reload the list
                        }, 300);
                    }
                } else {
                    alert(data.message || 'Error rejecting organization');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Error rejecting organization');
            });
        }

        function showEmptyState(message) {
            const container = document.getElementById('pending-orgs-container');
            if (container) {
                container.innerHTML = `
                    <div class="empty-state">
                        <div style="font-size: 3rem;">📋</div>
                        <p>${message}</p>
                    </div>
                `;
            }
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
                        loadPendingOrganizations(); // Refresh pending list in case it was a pending org
                        loadUserSelects(); // Refresh selects
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
            return date.toISOString().slice(0, 16);
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
        function loadUsers() {
            fetch('/api/users')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        // Filter out users with # in username (pending) from the main users list
                        users = data.data.filter(user => !user.username.startsWith('#'));
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
                    donors = donorsData.data.filter(user => !user.username.startsWith('#'));
                    updateSelect('donor', donors);
                }
                if (volunteersData.success) {
                    volunteers = volunteersData.data;
                    updateSelect('volunteer', volunteers);
                }
                if (orgsData.success) {
                    organizations = orgsData.data.filter(user => !user.username.startsWith('#'));
                    updateSelect('organization', organizations);
                }
            })
            .catch(error => {
                console.error('Error loading user selects:', error);
            });
        }

        function updateSelect(selectId, items) {
            const select = document.getElementById(selectId);
            if (!select) return;
            
            select.innerHTML = '<option value="">None</option>';
            items.forEach(item => {
                const option = document.createElement('option');
                option.value = item.id;
                option.textContent = `${item.first_name} ${item.last_name}`;
                select.appendChild(option);
            });
        }

        function renderUsersTable(users) {
            const tbody = document.getElementById('users-table-body');
            if (!tbody) return;
            
            tbody.innerHTML = '';
            
            users.forEach(user => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td>${user.id}</td>
                    <td>${user.username}</td>
                    <td>${user.first_name} ${user.last_name}</td>
                    <td>${user.email}</td>
                    <td>${user.phone || '-'}</td>
                    <td><span class="badge" style="background: #6366f1">${user.role}</span></td>
                    <td>${new Date(user.created_at).toLocaleDateString()}</td>
                    <td>
                        <button class="btn btn-edit btn-sm" onclick='openUserModal(${JSON.stringify(user).replace(/'/g, "\\'")})'>Edit</button>
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
                        <button class="btn btn-edit btn-sm" onclick='openDonationModal(${JSON.stringify(donation).replace(/'/g, "\\'")})'>Edit</button>
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

@app.route('/api/organizations/pending')
def get_pending_organizations():
    """Get all organizations with username starting with # (pending approval)"""
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT * FROM users 
                WHERE role = 'organization' 
                AND username LIKE '#%'
                ORDER BY created_at DESC
            """)
            pending_orgs = cursor.fetchall()
            return jsonify({'success': True, 'data': pending_orgs})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        conn.close()

@app.route('/api/organizations/<int:org_id>/approve', methods=['POST'])
def approve_organization(org_id):
    """Approve organization by removing # from username"""
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Get current username
            cursor.execute("SELECT username FROM users WHERE id = %s", (org_id,))
            result = cursor.fetchone()
            
            if not result:
                return jsonify({'success': False, 'message': 'Organization not found'}), 404
            
            username = result['username']
            if not username.startswith('#'):
                return jsonify({'success': False, 'message': 'Organization is already approved'}), 400
            
            # Remove # from username
            new_username = username[1:]  # Remove the first character (#)
            
            cursor.execute("""
                UPDATE users 
                SET username = %s, updated_at = NOW()
                WHERE id = %s
            """, (new_username, org_id))
            
            conn.commit()
            return jsonify({'success': True, 'message': 'Organization approved successfully'})
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        conn.close()

@app.route('/api/organizations/<int:org_id>/reject', methods=['DELETE'])
def reject_organization(org_id):
    """Reject organization by deleting the record"""
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Check if it's a pending organization
            cursor.execute("SELECT username FROM users WHERE id = %s AND role = 'organization'", (org_id,))
            result = cursor.fetchone()
            
            if not result:
                return jsonify({'success': False, 'message': 'Organization not found'}), 404
            
            username = result['username']
            if not username.startswith('#'):
                return jsonify({'success': False, 'message': 'Cannot reject approved organization'}), 400
            
            # Delete the organization
            cursor.execute("DELETE FROM users WHERE id = %s", (org_id,))
            conn.commit()
            return jsonify({'success': True, 'message': 'Organization rejected and deleted'})
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        conn.close()

@app.route('/api/documents/<path:document_path>')
def serve_document(document_path):
    """Serve uploaded documents"""
    try:
        # URL decode the path to handle special characters
        from urllib.parse import unquote
        document_path = unquote(document_path)
        
        # Extract just the filename from the path
        filename = os.path.basename(document_path)
        
        # Get project root directory
        project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        
        # Construct full file path - try different possible locations
        possible_paths = [
            os.path.join(UPLOAD_FOLDER, filename),  # Direct in assets folder
            os.path.join(UPLOAD_FOLDER, document_path),  # Full path as provided
            os.path.join(project_root, document_path),  # Project root with stored path
            os.path.join(project_root, 'backend', 'src', 'assets', filename),  # Backend assets
            os.path.join(project_root, 'backend', 'src', 'assets', document_path),  # Backend with stored path
            os.path.join(project_root, 'backend', 'src', document_path),  # Backend with stored path
            os.path.join(project_root, filename),  # Project root with just filename
            document_path,  # Absolute path as stored
            os.path.join(os.path.dirname(__file__), filename),  # Admin app directory
            os.path.join(os.path.dirname(__file__), document_path),  # Admin app full path
        ]
        
        print(f"Looking for document: {filename}")
        print(f"Document path: {document_path}")
        print(f"UPLOAD_FOLDER: {UPLOAD_FOLDER}")
        print(f"Project root: {project_root}")
        
        file_path = None
        for path in possible_paths:
            print(f"Trying path: {path}")
            if os.path.exists(path):
                file_path = path
                print(f"Found file at: {file_path}")
                break
        
        if not file_path:
            # If file not found, return a helpful error page
            print(f"File not found. Searched in:")
            for path in possible_paths:
                print(f"  - {path}")
            return f"""
            <html>
            <head><title>Document Not Found</title></head>
            <body style="background: #1e293b; color: white; font-family: Arial; padding: 2rem;">
                <h1>Document Not Found</h1>
                <p>The requested document could not be found: {filename}</p>
                <p>Searched in:</p>
                <ul>
                    {"".join([f"<li>{path}</li>" for path in possible_paths])}
                </ul>
                <p>Please check if the file exists in the uploads directory.</p>
                <a href="/" style="color: #6366f1;">Return to Admin Panel</a>
            </body>
            </html>
            """, 404
        
        # Determine file type and serve appropriately
        file_ext = os.path.splitext(file_path)[1].lower()
        
        if file_ext == '.pdf':
            # For PDFs, serve with appropriate headers
            return send_file(
                file_path,
                mimetype='application/pdf',
                as_attachment=False,
                download_name=filename
            )
        elif file_ext in ['.jpg', '.jpeg', '.png', '.gif', '.bmp']:
            # For images
            return send_file(
                file_path,
                mimetype=f'image/{file_ext[1:]}',
                as_attachment=False
            )
        elif file_ext in ['.doc', '.docx']:
            # For Word documents, serve as download
            return send_file(
                file_path,
                mimetype='application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                as_attachment=True,
                download_name=filename
            )
        else:
            # For other files, serve as download
            return send_file(
                file_path,
                as_attachment=True,
                download_name=filename
            )
            
    except Exception as e:
        return f"""
        <html>
        <head><title>Error</title></head>
        <body style="background: #1e293b; color: white; font-family: Arial; padding: 2rem;">
            <h1>Error Loading Document</h1>
            <p>Error: {str(e)}</p>
            <a href="/" style="color: #6366f1;">Return to Admin Panel</a>
        </body>
        </html>
        """, 500

@app.route('/api/users', methods=['GET', 'POST'])
def handle_users():
    if request.method == 'GET':
        role = request.args.get('role')
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                if role:
                    # For role-specific queries, exclude pending organizations from regular users
                    if role == 'organization':
                        cursor.execute("SELECT * FROM users WHERE role = %s AND NOT username LIKE '#%' ORDER BY created_at DESC", (role,))
                    else:
                        cursor.execute("SELECT * FROM users WHERE role = %s ORDER BY created_at DESC", (role,))
                else:
                    # Get all users except pending organizations (those with # in username)
                    cursor.execute("SELECT * FROM users WHERE NOT (role = 'organization' AND username LIKE '#%') ORDER BY created_at DESC")
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
                    
                # For new users, ensure username doesn't have # unless it's a pending organization
                username = data.get('email').split('@')[0]
                if data.get('role') == 'organization' and data.get('is_pending'):
                    username = '#' + username
                
                cursor.execute("""
                    INSERT INTO users 
                    (username, email, password_hash, first_name, last_name, phone, role, created_at, updated_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
                """, (
                    username,
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
    # Create uploads directory if it doesn't exist
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    
    # Start Flask in a separate thread
    flask_thread = threading.Thread(target=run_flask)
    flask_thread.daemon = True
    flask_thread.start()
    
    # Create and start the webview window
    window = webview.create_window(
        'Food Donation Admin - Organization Approval',
        'http://127.0.0.1:3000',
        width=1400,
        height=900,
        min_size=(1000, 700),
        text_select=True
    )
    
    webview.start(debug=True)
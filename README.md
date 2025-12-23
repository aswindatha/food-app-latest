# Food Donation Platform

A platform connecting food donors with volunteers and organizations to reduce food waste and fight hunger.

## Prerequisites

- Node.js 16+ and npm 8+
- MySQL 8.0+

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd food-app
   ```

2. **Install dependencies**
   ```bash
   # Backend dependencies
   cd backend
   npm install
   
   # Frontend dependencies (if applicable)
   cd ../frontend
   npm install
   ```

3. **Set up the database**
   - Create a MySQL database named `food_app`
   - The backend is configured to use MySQL with:
     - Host: localhost
     - Port: 3306
     - User: root
     - Password: root

4. **Start the application**
   ```bash
   # Start backend server
   cd backend
   npm run dev
   
   # Start frontend (if applicable)
   cd ../frontend
   npm start
   ```

## Project Structure

- `/backend` - Node.js/Express backend API
  - `/src` - Source code
    - `/config` - Database configuration
    - `/controllers` - API controllers
    - `/models` - Database models
    - `/routes` - API routes
    - `/middleware` - Authentication middleware
  - `/test` - Test files
- `/frontend` - React frontend (if applicable)

## API Documentation

Comprehensive API documentation is available at `backend/api.md`. It includes:

- **Authentication Endpoints**: Register, Login, User Profile
- **Donation Endpoints**: CRUD operations, volunteer assignment
- **Organization Endpoints**: Claim donations, manage volunteers
- **Volunteer Endpoints**: Handle requests, manage assignments
- **Conversation Endpoints**: Messaging system

Each endpoint includes request/response payloads, UI integration details, and business logic flow.

## Available Scripts

### Backend
- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon
- `npm test` - Run tests
- `npm run test:watch` - Run tests in watch mode
- `npm run migrate` - Run database migrations

### Frontend (if applicable)
- `npm start` - Start development server
- `npm run build` - Build for production

## Environment Variables

Create a `.env` file in the backend directory with the following variables:

```env
# Database (MySQL)
DB_HOST=localhost
DB_PORT=3306
DB_NAME=food_app
DB_USER=root
DB_PASS=root

# JWT Secret (generate a secure secret for production)
JWT_SECRET=your-secret-key

# Server
PORT=5000
NODE_ENV=development
```

## Database Migration

The application has been migrated from PostgreSQL to MySQL. Key changes:
- Database driver changed from `pg` to `mysql2`
- Default port changed from 5432 to 3306
- Configuration updated in `src/config/db.js`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
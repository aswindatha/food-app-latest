# Food App Backend

This is the backend for the Food Donation App, built with Node.js, Express, and PostgreSQL.

## Prerequisites

- Node.js (v14 or higher)
- PostgreSQL (v12 or higher)
- npm or yarn

## Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   - Copy `.env.example` to `.env`
   - Update the database credentials and other settings in `.env`

4. **Set up PostgreSQL**
   - Make sure PostgreSQL is running
   - Create a new database named `food_app` (or update the `DB_NAME` in `.env`)
   - Update the database user and password in `.env`

5. **Run migrations**
   ```bash
   npm run migrate
   ```
   This will:
   - Create the database if it doesn't exist
   - Create all tables
   - Add sample data

6. **Start the server**
   ```bash
   # Development
   npm run dev

   # Production
   npm start
   ```

The server will be running at `http://localhost:5000` by default.

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register a new user
  ```json
  {
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "first_name": "Test",
    "last_name": "User",
    "role": "donor"
  }
  ```

- `POST /api/auth/login` - Login
  ```json
  {
    "emailOrUsername": "test@example.com",
    "password": "password123"
  }
  ```

- `GET /api/auth/me` - Get current user (requires authentication)

## Development

- Use `npm run dev` for development with hot-reload
- The server will restart automatically when you make changes

## Testing

To be implemented

## Deployment

To be implemented

## License

MIT

# Food Donation Platform

A platform connecting food donors with volunteers and organizations to reduce food waste and fight hunger.

## Prerequisites

- Node.js 16+ and npm 8+
- Java 17 or later
- PostgreSQL 13+

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd food-app
   ```

2. **Install dependencies**
   ```bash
   npm run install:all
   ```

3. **Set up the database**
   - Create a PostgreSQL database named `food_app`
   - Update database configuration in `application.properties`

4. **Start the application**
   ```bash
   # Start both frontend and backend
   npm start
   
   # Or start them separately
   npm run start:backend
   npm run start:frontend
   ```

## Project Structure

- `/app` - Main application code
  - `/login-and-registration` - Authentication module
    - `/login-and-registration-ui` - React frontend
    - `/login-and-registration-backend` - Spring Boot backend
  - `/donor` - Donor module (future)
  - `/volunteer` - Volunteer module (future)
  - `/organization` - Organization module (future)

## Available Scripts

- `npm start` - Start both frontend and backend
- `npm run start:frontend` - Start the frontend development server
- `npm run start:backend` - Start the backend server
- `npm run build` - Build the frontend for production

## Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Database
DB_URL=jdbc:postgresql://localhost:5432/food_app
DB_USERNAME=user
DB_PASSWORD=password

# JWT Secret (generate a secure secret for production)
JWT_SECRET=your-secret-key
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
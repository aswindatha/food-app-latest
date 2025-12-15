# Project Structure

app/
├── login-and-registration/
│   ├── login-and-registration-ui/
│   │   └── LoginRegisterPage.tsx
│   └── login-and-registration-backend/
│       └── AuthController.java
│
├── donor/
│   ├── donor-ui/
│   │   └── DonorDashboard.tsx
│   └── donor-backend/
│       └── DonorController.java
│
├── volunteer/
│   ├── volunteer-ui/
│   │   └── VolunteerDashboard.tsx
│   └── volunteer-backend/
│       └── VolunteerController.java
│
├── organization/
│   ├── organization-ui/
│   │   └── OrganizationDashboard.tsx
│   └── organization-backend/
│       └── OrganizationController.java
│
├── administrator/
│   ├── administrator-ui/
│   │   └── AdminDashboard.tsx
│   └── administrator-backend/
│       └── AdminController.java
│
├── database/
│   ├── schema.sql
│   ├── data.sql
│   └── seed-data.sql
│
└── common/
    ├── shared-dto/
    │   └── ApiResponseDTO.java
    └── shared-utils/
        └── JwtUtil.java
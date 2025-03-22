# AP Arena Facility Booking & Database Security System

## Overview
This project is a web-based facility booking system designed for AP Arena, a premium sports complex offering various sports facilities such as volleyball courts, badminton courts, basketball courts, squash courts, and swimming pools. The system allows tournament organizers and individual customers to book facilities, ensuring efficient management through an integrated relational database hosted on Microsoft SQL Server.

The project also emphasizes robust database security, addressing key security objectives: data integrity, availability, confidentiality, and non-repudiation. It incorporates advanced features such as auditing, automated backups, data classification, and role-based access control (RBAC).

## Features
### Core Functionalities
1. Facility Booking:
    - Bulk bookings for tournament organizers with participant registration.
    - Single facility bookings for individual customers.
2. User Roles:
   - Data Admin, Complex Manager, Tournament Organizer, and Individual Customer.
   - Role-specific permissions to ensure secure operations.

### Database Security
1. Auditing:
   - Tracks all database activities, user login attempts, and data changes.
2. Backup & Recovery:
   - Automated backups with a Recovery Point Objective (RPO) of 6 hours.
   - Easy data recovery for accidental or intentional deletions.
3. Data Protection:
   - Data classification and encryption with automatic unmasking for authorized users.
4. RBAC:
   - Role-based access control with detailed authorization and audit matrices.
  
## Implementation
### Database Design
- Designed to align with business rules and security requirements.
- Includes a complete database schema with security and access configurations.
### Security Enhancements
- MS-SQL scripts for secure implementation of permissions, data protection, and auditing.
- Inline comments for ease of understanding and reproducibility.


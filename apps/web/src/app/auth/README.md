Auth folder: place to add NextAuth or JWT middleware.

Notes:
- Add NextAuth configuration under `app/api/auth/[...nextauth]/route.ts` (or in `pages/api` for older Next.js).
- Add middleware if you want to protect routes (Next.js `middleware.ts` at project root is required for global route protection).

# ResQLink Admin Dashboard

The web-based administration panel and backend infrastructure for the ResQLink platform.

## Features
- **Real-Time Map & Dispatch:** Live tracking of victims and volunteers using Supabase Realtime and Google Maps.
- **Incident Management:** View, filter, and resolve SOS incidents in real-time.
- **Analytics & Reporting:** Dynamic charts showing user growth, SOS frequency, and volunteer response times.
- **User & Volunteer Management:** Manage accounts, approve volunteer applications, and assign roles.

## Tech Stack
- **Framework:** [Next.js](https://nextjs.org/) (App Router)
- **Styling:** [Tailwind CSS](https://tailwindcss.com/) + Vanilla CSS
- **Database & Auth:** [Supabase](https://supabase.com/) (PostgreSQL)
- **Edge Functions:** Supabase Deno Edge Functions for notification broadcasts

## Getting Started

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Run the development server:**
   ```bash
   npm run dev
   ```

3. **Open the browser:**
   Navigate to [http://localhost:3000](http://localhost:3000)

## Supabase Deployment
To deploy edge functions and database migrations:
```bash
npx supabase start
npx supabase functions deploy notify-volunteers
npx supabase functions deploy assign-volunteer
```

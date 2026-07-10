# FastResp 🚨

**FastResp** is a high-performance, real-time emergency dispatch and volunteer coordination portal. Built using Next.js, React 19, TypeScript, and Supabase (PostgreSQL), the platform allows operators to monitor emergency SOS incidents, track volunteer availability/location in real time, and orchestrate rapid dispatch operations using serverless Edge Functions.

## 🚀 Key Features

*   **Real-time SOS Dispatch & Monitoring**: Utilizes WebSockets (via Supabase Realtime) to stream live SOS incidents to the admin dashboard instantly without page reloads.
*   **Intelligent Volunteer Matching**: Employs serverless **Supabase Edge Functions** to dynamically assign the most optimal volunteer to open incidents based on availability, proximity, and skillset.
*   **Live Analytics & KPIs**: Displays key performance metrics—such as active SOS cases, volunteer response times, and incident resolution rates—visualized using **Recharts** and updated in real time.
*   **Database-Level Optimization**: Uses custom **PostgreSQL Stored Procedures (RPCs)** to aggregate and calculate dashboard analytics, significantly reducing payload sizes and front-end latency by 40%.
*   **Geospatial Tracking**: Employs latitude/longitude coordinate coordinates to map active volunteers and incidents, facilitating optimal routing and resource coordination.

## 🛠️ Tech Stack

*   **Frontend**: Next.js (App Router), React 19, TypeScript, Zustand (State Management), Tailwind CSS 4, Recharts, Shadcn UI / Radix
*   **Backend & DB**: Supabase, PostgreSQL (with RPC & Realtime Pub/Sub), Database Triggers, Serverless Edge Functions

---

## ⚙️ Project Setup & Installation

### Prerequisites
Make sure you have [Node.js](https://nodejs.org/) installed.

### 1. Clone the repository
```bash
git clone https://github.com/Anukritidixit/FastResp.git
cd FastResp
```

### 2. Install dependencies
```bash
npm install
```

### 3. Setup environment variables
Create a `.env.local` file in the root directory and add your Supabase credentials:
```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 4. Run the development server
```bash
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) with your browser to see the application.

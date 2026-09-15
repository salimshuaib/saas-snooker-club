# S&B Manager Push Notification Backend

This is a standalone Node.js server that listens to your Firebase Firestore in real-time and sends Push Notifications (FCM) to the Club Owners when a new booking is made. 

It is designed to be hosted for **free** on [Render.com](https://render.com) using their "Web Service" tier.

## How to Deploy on Render.com

1. **Commit and Push to GitHub:**
   Ensure this `render_backend` folder is pushed to your GitHub repository.

2. **Generate Firebase Service Account Key:**
   - Go to your [Firebase Console](https://console.firebase.google.com).
   - Click the Gear Icon ?? (Project Settings) -> **Service Accounts**.
   - Click **"Generate new private key"**.
   - A `.json` file will download to your computer. Open it in a text editor (like Notepad) and copy all the text inside.

3. **Create the Render Web Service:**
   - Go to [Render.com](https://dashboard.render.com/) and create a free account.
   - Click **New +** -> **Web Service**.
   - Connect your GitHub account and select your `Saas Snooker Club` repository.
   - Set the following details:
     - **Name:** snooker-push-notifications
     - **Root Directory:** `render_backend`
     - **Environment:** `Node`
     - **Build Command:** `npm install`
     - **Start Command:** `npm start`
     - **Instance Type:** Free

4. **Add Environment Variables:**
   - Scroll down to the **Advanced** section and click **Add Environment Variable**.
   - **Key:** `FIREBASE_SERVICE_ACCOUNT_JSON`
   - **Value:** *Paste the entire contents of the `.json` file you downloaded in Step 2 here.*

5. **Deploy!**
   - Click **Create Web Service**.
   - Render will start your server. 

### Keep the Free Server Awake
Render will put Free Web Services to sleep if they do not receive web traffic for 15 minutes. If it sleeps, it will stop checking for bookings! 
To fix this, you can set up a free pinger:
1. Copy the URL Render gives your new service (e.g., `https://snooker-push-notifications.onrender.com`).
2. Go to [cron-job.org](https://cron-job.org/) (a 100% free service).
3. Create a free account, click **Create Cronjob**.
4. Paste the URL, and set it to execute every **14 minutes**.
This will trick Render into thinking a user is visiting the site, keeping your Push Notification server awake forever for free!


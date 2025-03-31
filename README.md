# 🚀 Flutter Job Application App  
A mobile app that allows users to browse and apply for jobs using a **Tinder-style swipe interface**. Users can swipe through job listings, apply with their stored resume, and manage their profile with work experience and education details.

---

## 📌 Features  

### 🔥 Job Search & Swipe UI  
- **Search Bar** – Filter job listings by **job title, location, or keywords**.  
- **Job Cards** – Display job details like **title, company logo, description, and source**.  
- **Swipe Actions**:  
  - **Swipe Left** – Discard the job (it won’t be shown again).  
  - **Swipe Right** – Open job application page with **pre-filled user details (where applicable)**.  
- **Tap-to-Expand** – Tap on a job card to view full job details.  

### 🌐 Job Listings Fetching  
- **Fetch from APIs** (LinkedIn, Indeed, etc.) or **Web Scraping** for sites without APIs.  
- **Ensure data consistency** across different sources.  
- **Local Caching** – Store recently fetched jobs for a smoother experience.  

### 🏠 User Profile Management  
- **Profile Form** to enter/edit:  
  - Name  
  - Work Experience (Job title, Start/End date, Description)  
  - Education (University, Degree, Graduation Year)  
- **Resume Upload** – Supports **PDF, DOC**, and other common formats.  
- **Local Storage** – Profile & resume stored **securely on the device**.  

### ⚡ Application Auto-Fill  
- **Prefill job application fields** (Name, Email, Resume) where supported.  
- **Fallback Redirection** – Redirect users to external job pages if auto-fill is not possible.  

### 📂 Local Storage  
- **Uses SQLite or Shared Preferences** for profile data and resume storage.  
- **Tracks swiped jobs** to prevent repeat listings.  

### 🎨 UI & Animations  
- **Material Design 3** for a modern, intuitive experience.  
- **Smooth swipe animations** for job cards.  
- **Tap-to-expand animations** for job details.  

### 🛠️ Additional Features  
- **Job History** – Keep track of swiped jobs to avoid duplicates.  
- **Settings & Preferences** – Toggle job notifications, filter jobs by location.  
- **Error Handling** – Manage missing data, network issues gracefully.  
- **Privacy & Security** – Ensure **secure** handling of user data (e.g., resume storage).  

---

## 📌 Tech Stack  
- **Flutter SDK** – Cross-platform mobile development.  
- **Dart** – App programming language.  
- **SQLite / Shared Preferences** – Local data storage.  
- **Dio / HTTP** – API calls & web scraping.  
- **Flutter Animations** – Swipe and UI transitions.  

---

## 🏗️ Project Setup  

### 🔧 Prerequisites  
Make sure you have the following installed:  
- [Flutter SDK](https://flutter.dev/docs/get-started/install)  
- Dart  
- Android Studio / VS Code (with Flutter extension)  
- Git  

### 🚀 Clone the Repository  
```sh
git clone https://github.com/agamairi/job-swipe.git
cd job-application-app
```

### 📦 Install Dependencies  
```sh
flutter pub get
```

### 🔨 Run the App  
```sh
flutter run
```

---

## 🔥 Features in Development  
- [ ] Implement **Web Scraping** for job listings  
- [ ] Support **Job History Tracking**  
- [ ] **Optimize Swipe Animations**  
- [ ] Add **Dark Mode**  

---

## 🚀 Contributing  
Want to contribute? **Fork** the repo, create a new branch, and submit a pull request!  

---

## 🛠️ Troubleshooting  

### 🔴 App Fails to Start  
- Ensure all dependencies are installed:  
  ```sh
  flutter pub get
  ```
- Check Flutter version:  
  ```sh
  flutter --version
  ```

### 🔴 Job Listings Not Fetching  
- Ensure internet connectivity.  
- Debug API calls using:  
  ```sh
  flutter run --verbose
  ```

---

## 📜 License  
This project is licensed under the **MIT License**.  

---

## 📞 Contact  
For any questions, feel free to reach out via **[GitHub Issues](https://github.com/agamairi/job-swipe/issues)**.  


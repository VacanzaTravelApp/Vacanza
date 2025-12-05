// firebase.js

import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyBjBpzaQ6X5LdZR-Oxft8eh1Sg4q5OknWE",
  authDomain: "vacanza-b364c.firebaseapp.com",
  projectId: "vacanza-b364c",
  storageBucket: "vacanza-b364c.firebasestorage.app",
  messagingSenderId: "424211182688",
  appId: "1:424211182688:web:7e4c7ddeb6c7ed04e3bf05",
  measurementId: "G-CRPL3K2FG9"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Export Firebase services
export const auth = getAuth(app);
export default app;

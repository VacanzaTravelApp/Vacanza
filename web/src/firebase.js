// firebase.js

// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
// import { getAnalytics } from "firebase/analytics"; 👈 Bu satırı kaldırdık

// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBubQwHOJPQfK-kZMeaxC3gcbZMuZIjARM",
  authDomain: "vacanza-b563c.firebaseapp.com",
  projectId: "vacanza-b563c",
  storageBucket: "vacanza-b563c.firebasestorage.app",
  messagingSenderId: "376677055070",
  appId: "1:376677055070:web:086882466450b2297352cf",
  measurementId: "G-9QDBWYT7BQ" 
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);


// 🚀 Ek: Authentication'ı export etmeyi unutmayalım!
import { getAuth } from "firebase/auth";

export const auth = getAuth(app); 
export default auth; 

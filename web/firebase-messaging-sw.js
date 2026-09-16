importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAiEO1peZc3AnSVAB1N6-ZlvEi966pHNMo",
  appId: "1:476933292121:web:3bff354476104bcd36f148",
  messagingSenderId: "476933292121",
  projectId: "saas-snooker-club",
  authDomain: "saas-snooker-club.firebaseapp.com",
  storageBucket: "saas-snooker-club.firebasestorage.app",
});

const messaging = firebase.messaging();

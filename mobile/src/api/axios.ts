import axios from 'axios';
import { Platform } from 'react-native';

// Configure axios baseURL
// For web: use relative path (same origin) to avoid CORS issues
// API is served from the same origin via Nginx proxy at /api/*
if (Platform.OS === 'web') {
  // On web, checking if we are in development (localhost) or production
  // @ts-ignore
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
      axios.defaults.baseURL = 'http://localhost:8086';
  } else {
      // In production, use relative path so requests go to same origin (Nginx proxy)
      axios.defaults.baseURL = '';
  }
} else {
  // For native platforms, use localhost in development
  // In production, this should be configured via environment variable
  const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:8086';
  axios.defaults.baseURL = API_URL;
}

axios.defaults.timeout = 10000;

// Add request interceptor for debugging
axios.interceptors.request.use(
  (config) => {
    console.log('API Request:', config.method?.toUpperCase(), config.url);
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add response interceptor for error handling
axios.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
      console.error('Response status:', error.response.status);
    }
    return Promise.reject(error);
  }
);

export default axios;

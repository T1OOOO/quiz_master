import axios from 'axios';

// Configure axios baseURL for development
// Backend runs on port 8080
axios.defaults.baseURL = 'http://localhost:8080';
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
